# OCI Bootstrap

This directory is reserved for the bootstrap prerequisites that have to exist
before the steady-state OCI platform stack can be applied.

It records how to create or recover the minimum chicken-and-egg resources:

- OCI Terraform state prerequisites;
- base compartment and policy prerequisites, if they are not created directly in
  the tenancy;
- maintainer-run commands for the initial bootstrap or recovery path.

Bootstrap is maintainer-run and must not be triggered automatically by CI. Future
Terraform automation belongs to the steady-state stack in [`../`](../), while
this directory remains for explicit bootstrap or recovery operations only.

Do not put Prow, DriverKit, OCIR, or production job capacity here. Those belong
to the steady-state stack in [`../`](../).
