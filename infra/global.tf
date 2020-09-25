module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.5.0"
  namespace  = "falco"
  stage      = "demo"
  name       = "test-infra"
  attributes = []
  delimiter  = "-"

  tags = {}
}

locals {
  cluster_name = module.label.id
}
