resource "oci_objectstorage_bucket" "prow_logs" {
  # checkov:skip=CKV_OCI_7:Prow reads logs directly; no object-event consumer is configured.
  # checkov:skip=CKV_OCI_9:Prow logs use OCI-managed encryption; a customer-managed Vault key is not part of this stack.
  compartment_id = var.compartment_ocid
  namespace      = var.object_storage_namespace
  name           = var.prow_logs_bucket_name

  access_type   = "NoPublicAccess"
  storage_tier  = "Standard"
  auto_tiering  = "InfrequentAccess"
  versioning    = "Enabled"
  freeform_tags = local.tags
}

resource "oci_objectstorage_object_lifecycle_policy" "prow_logs" {
  # The Object Storage service policy is a prerequisite managed by bootstrap.
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
