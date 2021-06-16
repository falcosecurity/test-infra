terraform {
  required_version = "1.0.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.45.0"
    }
  }
}
