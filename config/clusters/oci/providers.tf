provider "oci" {
  auth                = var.auth
  config_file_profile = var.config_file_profile
  region              = var.region
}

# Provider for identity resources, which must be created in the tenancy home region.
provider "oci" {
  alias               = "home"
  auth                = var.auth
  config_file_profile = var.config_file_profile
  region              = var.home_region
}
