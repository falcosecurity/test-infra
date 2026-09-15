terraform {
  required_version = ">= 1.3.7"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "= 9.1.0"
    }
  }
}
