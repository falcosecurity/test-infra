# Falco Test Infra on OCI

This directory will contain the OCI/OKE replacement for the current AWS/EKS
Prow infrastructure.

The root of this directory is the steady-state OCI platform stack. This is the
stack that creates the OCI/OKE infrastructure and that future Terraform
plan/apply automation will manage after the first live apply. It will contain:

- OKE node pools for Prow, generic jobs, automation jobs, and DriverKit;
- Actions Runner Controller runner substrate for cloudful GitHub Actions;
- OCIR repositories for `test-infra/*` images;
- OCI Object Storage for new Prow logs;
- workload identities for OCI access;
- AWS WebIdentity integration for the AWS distribution paths that remain in
  use during this migration.

The platform intentionally does not copy the old AWS/EKS shape one-to-one. The
AWS cluster had old Kubernetes/versioning pressure, broad node pools, GP2-era
storage defaults, and DriverKit reliability concerns. The OCI target starts with
separate node pools for Prow, generic jobs, automation, and DriverKit, Kubernetes
`v1.35.0`, larger boot volumes for build-heavy pools, and pinned node images for
production applies.

The [`bootstrap/`](bootstrap/) directory is different: it is a maintainer-run
record for the state and IAM prerequisites needed before this platform stack can
be applied. It is not a CI-managed Terraform stack and must not contain the OKE,
Prow, DriverKit, OCIR, or runner capacity managed here.

Creation flow: bootstrap the prerequisites manually, apply this platform stack
manually once to create the OKE/ARC substrate, then let future automated
plan/apply reconcile this stack from Falco-owned OKE runners.

## Local Bootstrap Flow

Bootstrap:

```shell
cd config/clusters/oci/bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
terraform output platform_backend_config
```

First platform apply:

```shell
cd config/clusters/oci
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

The committed `backend.hcl.example` contains only placeholders. Keep the real
`backend.hcl` and `terraform.tfvars` local.

Before production apply:

- set `kubernetes_api_allowed_cidrs` to the maintainer/network ranges that need
  temporary API access;
- pin `node_pool_image_ids` for both `x86` and `arm`;
- verify OCI shape quota for every configured node pool;
- add the Kubernetes-side taints needed to preserve the current Prow/job
  isolation model. The OCI Terraform node pool resource supports initial node
  labels, but not initial node taints in the provider schema currently validated
  for this branch.

The OCI stack must not use the AWS Terraform backend. Cloudful GitHub Actions
must run on Falco-owned OKE ephemeral runners before they receive Falco-owned
cloud identity.
