# OCI Bootstrap

This Terraform stack manages the platform's administrative prerequisites:

- a private, versioned Object Storage state bucket with `prevent_destroy`;
- the OCI compartment, when `create_compartment` is enabled;
- the OKE Cluster Autoscaler workload identity policy;
- the Prow log user, group and bucket-access policy;
- the tenancy-root Object Storage lifecycle service policy;
- separate Terraform plan/apply service users, groups and platform-access policies;
- the GitHub OIDC trust and its plan/apply identity mappings.

Set `create_compartment = false` and provide `existing_compartment_ocid` to use
an existing compartment. The `platform_backend_config` output provides the
backend settings for the [platform stack](../).

Bootstrap is run locally, outside CI. See the
[initial deployment instructions](../README.md#initial-deployment).

Apply bootstrap before the platform, then bind the autoscaler policy to the
created cluster as described below. IAM writes use `home_region`; platform and
state-bucket operations use `region`. Keep `cluster_name`, `compartment_name`
and `prow_logs_bucket_name` consistent with the platform. Policy and identity
changes require a separate maintainer-reviewed bootstrap apply; the platform CI
does not administer them or read bootstrap state.

The `prow_logs_user_id` output identifies the user whose Customer Secret Key is
created outside Terraform. Do not store that key in Terraform inputs or outputs.
Protect local bootstrap state and its backups; they are not CI artifacts.

## Controller identities

Set `oke_cluster_ocid` to the platform cluster OCID to create the autoscaler
policy. It authorizes only the `kube-system/cluster-autoscaler` service account
in that cluster, using the
[OKE workload identity configuration](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengusingclusterautoscaler_topic-Working_with_Cluster_Autoscaler_as_Cluster_Add-on.htm).
Leaving the input null creates no autoscaler policy; it does not fall back to
worker instance permissions. For a new cluster, use the
[initial deployment sequence](../README.md#initial-deployment) to create the
cluster before binding this policy and enabling the add-on.

The managed OKE cloud-controller-manager and Block Volume CSI controller use
the cluster resource principal. Worker instances do not need their controller
permissions. Additional cluster-principal policies are required when
[load balancer resources](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengconfiguringloadbalancersnetworkloadbalancers-subtopic.htm)
or [Block Volume resources](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingpersistentvolumeclaim_topic-Provisioning_PVCs_on_BV.htm)
are placed in other compartments. This platform keeps those resources in the
cluster compartment.

### Transition from instance principals

For an existing cluster with the former worker dynamic group and policies,
do not apply their removal before switching the autoscaler. Keep automatic
platform applies disabled during this maintainer-approved transition:

1. Set `oke_cluster_ocid` to the existing cluster OCID. Review a bootstrap plan
   limited to `oci_identity_policy.cluster_autoscaler`, and apply that saved
   plan. It must create only the new workload policy, without deleting the
   existing worker policies or dynamic group.
2. Review and apply the platform change to `authType=workload`, leaving
   `cluster_autoscaler_enabled=true`. Verify autoscaler health, absence of
   authorization errors and a controlled scale-up and scale-down.
3. Review and apply a full bootstrap plan to remove the former worker dynamic
   group and its compartment and tenancy policies. Verify that normal worker
   instances no longer have those grants, then check CSI provisioning/attachment
   and load balancer reconciliation before enabling untrusted jobs.

The targeted plan in step 1 is a one-time dependency transition, not the regular
deployment procedure. Use full plans afterwards and retain no broad worker
policy as a fallback.

## GitHub authentication

Create the token-exchange OAuth application manually in the same identity domain,
without administrator roles. Set `github_oidc_client_id` to its non-secret client
ID. The application remains outside Terraform; do not declare or import it as a
resource or data source. Oracle's
[App GET API](https://docs.oracle.com/en/cloud/paas/iam-domains-rest-api/op-admin-v1-apps-id-get.html)
returns the client secret by default. Keep that secret only in the restricted
GitHub environments described in the
[CI setup](../../../../tools/ci/README.md#activation-prerequisites).

The [federation configuration](terraform_federation.tf) checks the exact
Terraform workflow on `master` through `client_claim_name` and
`client_claim_values`. Each service-user mapping combines the environment
subject, OCI audience, branch and GitHub-hosted runner requirements in its rule,
without a wildcard fallback. Bootstrap pins OCI provider 9.1.0 independently
of the platform's provider version.

`github_oidc_enabled` defaults to `false`. Apply and inspect the disabled trust
and IAM grants first. API acceptance and an unchanged Terraform plan do not
verify rule evaluation during token exchange. Enable it only through a separately
reviewed local bootstrap apply, then verify accepted and rejected token exchanges
and both roles' permissions before running automatic platform deployment. Set it to
`false` and apply bootstrap to disable further exchanges. Do not rely on this
operation to revoke sessions already issued.

## Terraform CI identities

The `falco-terraform-plan` and `falco-terraform-apply` users are service users
with long-lived credential capabilities disabled. Adopt existing users into
`oci_identity_domains_user.terraform["plan"]` and
`oci_identity_domains_user.terraform["apply"]` before planning their adoption;
do not recreate them. Review the provider's first-read behavior before importing:
the configured `attributes` allowlist is not applied to the initial import read.
The OCI provider's user import ID has the form
`idcsEndpoint/<domain-url>/users/<user-id>`. Use a literal HTTPS URL without the
default `:443` suffix, matching the normalized endpoint in this configuration.
Protect import logs as well as state; the first response uses the API defaults.

Both roles can read platform resources and the platform state. For backend
locking, they can create and remove only the lock object. The apply role can
additionally manage platform resource types in the platform compartment,
configure the Prow log bucket and write the platform state. Neither role manages
IAM or the state bucket, reads bootstrap state, or deletes platform state
versions. The `platform_backend_config` output and these policies share the same
state key.

The kubeconfig data source requires `CLUSTER_USE`; the plan role receives this
permission only for `CreateKubeconfig`. Kubernetes RBAC bindings are not created
by this stack. The apply role's OKE management permissions are broader and must
only be assigned to the trusted apply identity.

Review and apply these grants locally. A successful Terraform validation checks
the configuration schema, not effective OCI authorization; verify both roles
using their federated sessions before enabling the CI workflow.
