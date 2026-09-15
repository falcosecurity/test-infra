# Falco Test Infra on OCI

This Terraform stack manages the OCI/OKE infrastructure:

- OKE node pools for the Prow platform, automation jobs, and DriverKit;
- OCIR repositories for `test-infra/*` images;
- OCI Object Storage for Prow logs.

The [`bootstrap/`](bootstrap/) stack manages the state bucket, compartment and
IAM prerequisites, including the autoscaler workload identity, the Prow log
identity and Object Storage service permissions. It is run locally and is
excluded from CI.

The [OCI Terraform workflow](../../../.github/workflows/terraform-oci.yml)
manages an existing platform using GitHub-hosted runners and OCI OIDC federation.
Federation is configured separately; see
[CI prerequisites and operation](../../../tools/ci/README.md#oci-terraform-plan-and-apply).

## Initial deployment

Apply bootstrap with `oke_cluster_ocid` unset when the cluster does not yet exist:

```shell
cd config/clusters/oci/bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
terraform output platform_backend_config
```

Create the platform without the autoscaler. Its IAM policy needs the cluster's
OCID, which is only available after creation:

```shell
cd config/clusters/oci
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform plan -var=cluster_autoscaler_enabled=false
terraform apply -var=cluster_autoscaler_enabled=false
terraform output -raw cluster_id
```

Set `oke_cluster_ocid` in the local bootstrap variables to that cluster OCID and
review and apply bootstrap again. Then run a full platform plan and apply without
the `cluster_autoscaler_enabled=false` override. The default is `true`; the
autoscaler uses the `kube-system/cluster-autoscaler` workload identity authorized
by bootstrap. This sequence does not grant controller permissions to worker
instances and requires no targeted apply.

`cluster_autoscaler_enabled` is also an operational switch. Setting it to `false`
removes the add-on, not the node pools; Terraform continues to ignore size changes
for autoscaled pools. Do not enable workloads that depend on scaling until the
add-on is enabled and its permissions and scaling behavior have been verified.

Complete the initial bootstrap first, including the Object Storage lifecycle
service policy.
Keep the cluster name and Prow log bucket name consistent between both stacks.
Platform CI requires the IAM prerequisites to exist but does not manage them or
access bootstrap state. The `prow_logs_user_id` output belongs to bootstrap.

For an existing cluster using instance-principal autoscaling, follow the
[workload identity transition](bootstrap/README.md#transition-from-instance-principals)
before applying these IAM and add-on changes.

The [backend example](backend.hcl.example) contains placeholders. Keep actual
backend configuration and variable files local.

Before production apply:

- set `kubernetes_api_allowed_cidrs` to the maintainer/network ranges that need
  API access;
- pin `node_pool_image_ids` for both `x86` and `arm`;
- verify OCI shape quota for every configured node pool;
- verify the pool-specific taints injected by [node metadata](locals.tf),
  including the autoscaler's scale-from-zero configuration. Terraform does not
  require manual node tainting.

The OCI stack must not use the AWS Terraform backend. Authenticated Terraform
GitHub Actions use GitHub-hosted runners with short-lived OCI security tokens
obtained through GitHub OIDC. The OAuth client secret belongs in the restricted
GitHub environments; no persistent OCI API signing key is used by the workflow.
