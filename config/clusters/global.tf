# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage

module "terraform_state_backend" {
  source     = "git::https://github.com/cloudposse/terraform-aws-tfstate-backend.git?ref=0.26.0"
  namespace  = var.app_namespace
  stage      = var.app_stage
  name       = var.app_name
  attributes = ["state"]

  terraform_backend_config_file_path = var.terraform_state_backend_config_file_path
  terraform_backend_config_file_name = var.terraform_state_backend_config_file_name
  force_destroy                      = var.terraform_state_backend_force_destroy
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

locals {
  cluster_name                  = module.label.id
  k8s_service_account_namespace = "default"
}
