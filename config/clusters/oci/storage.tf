resource "oci_objectstorage_bucket" "prow_logs" {
  compartment_id = var.compartment_ocid
  namespace      = var.object_storage_namespace
  name           = "falco-prow-logs"

  access_type   = "NoPublicAccess"
  storage_tier  = "Standard"
  auto_tiering  = "InfrequentAccess"
  versioning    = "Enabled"
  freeform_tags = local.tags
}

# Required for Object Storage to run the bucket lifecycle policy. Must live in the
# tenancy root.
resource "oci_identity_policy" "object_storage_lifecycle" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-os-lifecycle"
  description    = "Allow Object Storage to run lifecycle policies on Falco test-infra buckets."
  freeform_tags  = local.tags

  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in compartment ${var.compartment_name}",
  ]
}

resource "oci_objectstorage_object_lifecycle_policy" "prow_logs" {
  depends_on = [oci_identity_policy.object_storage_lifecycle]

  bucket    = oci_objectstorage_bucket.prow_logs.name
  namespace = var.object_storage_namespace

  rules {
    name        = "expire-logs"
    target      = "objects"
    action      = "DELETE"
    time_amount = 10
    time_unit   = "DAYS"
    is_enabled  = true

    object_name_filter {
      inclusion_prefixes = ["logs/", "pr-logs/"]
    }
  }

  rules {
    name        = "expire-noncurrent-versions"
    target      = "previous-object-versions"
    action      = "DELETE"
    time_amount = 3
    time_unit   = "DAYS"
    is_enabled  = true
  }

  rules {
    name        = "abort-incomplete-multipart"
    target      = "multipart-uploads"
    action      = "ABORT"
    time_amount = 7
    time_unit   = "DAYS"
    is_enabled  = true
  }
}
