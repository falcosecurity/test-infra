terraform {
  required_version = ">= 1.12.0"

  backend "oci" {
    bucket    = "falco-test-infra-terraform-state"
    namespace = "idg4joojefiy"
    key       = "bootstrap/driver-publishing.tfstate"
    region    = "eu-frankfurt-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.65.0"
    }
  }
}
