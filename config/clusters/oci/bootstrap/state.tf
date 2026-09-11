data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

resource "oci_objectstorage_bucket" "terraform_state" {
  compartment_id = local.platform_compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = var.terraform_state_bucket_name

  access_type   = "NoPublicAccess"
  storage_tier  = "Standard"
  versioning    = "Enabled"
  freeform_tags = var.tags

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = local.platform_compartment_id != null
      error_message = "Set existing_compartment_ocid when create_compartment is false."
    }
  }
}
