terraform {
  required_version = ">= 1.3.7"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 8.15.0, < 9.0.0"
    }
  }
}
