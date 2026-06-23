# Cluster Infrastructure

Provider-specific Terraform stacks live in this directory.

- [`aws/`](aws/) contains the existing AWS/EKS Prow infrastructure.
- [`oci/`](oci/) will contain the new OCI/OKE Prow infrastructure.

Keep provider states independent. OCI resources must not use the AWS Terraform
backend. The OCI bootstrap area is manual-only; future automation must target
the steady-state OCI platform stack, not the bootstrap Terraform.
