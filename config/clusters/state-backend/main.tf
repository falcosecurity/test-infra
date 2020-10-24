# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage

# The remote state backend is used also to manage the main infrastructure's
# state. The isolation can be done at workspace level.
# This remote state backend manages also the state of remote state backend 
# infrastructure itself.

module "terraform_state_backend" {
  source     = "git::https://github.com/cloudposse/terraform-aws-tfstate-backend.git?ref=0.26.0"
  namespace  = var.app_namespace
  stage      = var.app_stage
  name       = var.app_name
  attributes = ["state"]

  terraform_backend_config_file_path = "${path.module}"
  terraform_backend_config_file_name = var.terraform_state_backend_config_file_name
  force_destroy                      = var.terraform_state_backend_force_destroy
}

# The backend config for this backend infrastructure state is already created by the module
# above. This resource creates and manages the config for the "main" infrastructure
# (i.e. the test-infra).

resource "local_file" "main_infra_backend_config" {
  content         = module.terraform_state_backend.terraform_backend_config
  filename        = "${path.module}/../${var.terraform_state_backend_config_file_name}"
  file_permission = "0644"
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.5.0"
  namespace  = var.app_namespace
  stage      = var.app_stage
  name       = var.app_name
  attributes = []
  delimiter  = "-"
  tags       = {}
}
