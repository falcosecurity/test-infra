output "platform_compartment_id" {
  description = "Compartment OCID used by the steady-state OCI platform stack."
  value       = local.platform_compartment_id
}

output "prow_logs_user_id" {
  description = "OCI IAM user OCID used to create the Prow Object Storage Customer Secret Key outside Terraform."
  value       = oci_identity_domains_user.prow_logs.ocid
}

output "object_storage_namespace" {
  description = "OCI Object Storage namespace used by the platform Terraform backend."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "terraform_state_bucket_name" {
  description = "OCI Object Storage bucket used by the platform Terraform backend."
  value       = oci_objectstorage_bucket.terraform_state.name
}

output "platform_backend_config" {
  description = "Non-secret backend configuration values for config/clusters/oci."
  value = {
    bucket              = oci_objectstorage_bucket.terraform_state.name
    namespace           = data.oci_objectstorage_namespace.this.namespace
    key                 = local.platform_state_key
    region              = var.region
    auth                = var.auth
    config_file_profile = var.config_file_profile
  }
}
