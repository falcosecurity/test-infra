variable "terraform_state_backend_force_destroy" {
  type        = bool
  default     = false
  description = "Whether to allow the S3 remote state backend to be deleted. Useful when migrating the state and/or destroying all the resources."
}

variable "terraform_state_backend_config_file_name" {
  default     = "terraform_backend.tf"
  description = "The file name for the terraform backend config file."
}

variable "region" {
  default     = "eu-west-1"
  description = "AWS region"
}

variable "app_name" {}
variable "app_namespace" {}
variable "app_stage" {}
