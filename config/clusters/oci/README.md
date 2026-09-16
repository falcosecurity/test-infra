# Falco Test Infra on OCI

This Terraform stack manages the OCI/OKE infrastructure:

- OKE node pools for the Prow platform, automation jobs, and DriverKit;
- OCIR repositories for `test-infra/*` images;
- OCI Object Storage for Prow logs.

Administrative prerequisites are managed separately in [`bootstrap/`](bootstrap/).

See the [input example](terraform.tfvars.example) and
[backend example](backend.hcl.example) for the configuration format.
