# Required for Object Storage to run bucket lifecycle policies. Must live in the
# tenancy root.
resource "oci_identity_policy" "object_storage_lifecycle" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-os-lifecycle"
  description    = "Allow Object Storage to run lifecycle policies on Falco test-infra buckets."
  freeform_tags  = local.platform_tags

  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in compartment ${var.compartment_name}",
  ]
}
