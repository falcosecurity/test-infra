locals {
  parent_compartment_ocid = coalesce(var.parent_compartment_ocid, var.tenancy_ocid)
  platform_compartment_id = var.create_compartment ? oci_identity_compartment.test_infra[0].id : var.existing_compartment_ocid
}
