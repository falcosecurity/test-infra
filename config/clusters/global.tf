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
  cluster_name                       = module.label.id
  k8s_service_account_namespace      = "default"
  k8s_test_service_account_namespace = "test-pods"
}
