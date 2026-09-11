provider "oci" {
  auth                = var.auth
  config_file_profile = var.config_file_profile
  region              = var.region
}

# Identity (compartment, policy, user, group) writes must target the tenancy
# home region. Use this aliased provider for those resources only.
provider "oci" {
  alias               = "home"
  auth                = var.auth
  config_file_profile = var.config_file_profile
  region              = var.home_region
}
