variable "aws_account_id" {
  description = "AWS account owning the driver distribution bucket."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "The AWS account ID must contain exactly 12 digits."
  }
}

variable "aws_region" {
  description = "AWS region of the driver distribution bucket."
  type        = string
  default     = "eu-west-1"
}

variable "oke_oidc_issuer_url" {
  description = "Public OIDC issuer of the OKE build cluster."
  type        = string

  validation {
    condition     = can(regex("^https://objectstorage\\.eu-frankfurt-1\\.oraclecloud\\.com/n/[a-zA-Z0-9]+/b/oidc/o/[a-zA-Z0-9-]+$", var.oke_oidc_issuer_url))
    error_message = "Use the exact Frankfurt OKE OIDC issuer URL without a trailing slash."
  }
}

variable "role_name" {
  description = "Dedicated AWS role for publishing drivers from OKE."
  type        = string
  default     = "falco-prow-driver-publisher"
}

variable "bucket_name" {
  description = "Existing driver distribution bucket; this stack does not manage it."
  type        = string
  default     = "falco-distribution"
}
