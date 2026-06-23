resource "oci_identity_compartment" "test_infra" {
  count = var.create_compartment ? 1 : 0

  compartment_id = local.parent_compartment_ocid
  description    = "Falco test-infra OCI resources."
  name           = var.compartment_name
  freeform_tags  = var.tags
}
