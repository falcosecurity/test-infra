variable "auth" {
  description = "OCI Terraform provider authentication mode used by the maintainer running bootstrap."
  type        = string
  default     = "APIKey"
}

variable "config_file_profile" {
  description = "OCI CLI config profile used by the maintainer running bootstrap."
  type        = string
  default     = "FALCO_TEST_INFRA"
}

variable "region" {
  description = "OCI region where the Falco test-infra platform will run."
  type        = string
}

variable "home_region" {
  description = "OCI tenancy home region. Identity (compartment, policy) writes must target it."
  type        = string
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID. The tenancy OCID is also the root compartment OCID."
  type        = string
}

variable "create_compartment" {
  description = "Create the Falco test-infra compartment during bootstrap. Set to false when the compartment already exists."
  type        = bool
  default     = true
}

variable "parent_compartment_ocid" {
  description = "Parent compartment OCID for the Falco test-infra compartment. Defaults to the tenancy root compartment."
  type        = string
  default     = null
}

variable "existing_compartment_ocid" {
  description = "Existing Falco test-infra compartment OCID, required when create_compartment is false."
  type        = string
  default     = null
}

variable "compartment_name" {
  description = "Name of the Falco test-infra OCI compartment created by bootstrap."
  type        = string
  default     = "falco-test-infra"
}

variable "terraform_state_bucket_name" {
  description = "OCI Object Storage bucket used by the steady-state platform Terraform backend."
  type        = string
  default     = "falco-test-infra-terraform-state"
}

variable "cluster_name" {
  description = "Platform cluster name used for workload and Object Storage IAM policies. Must match the platform stack."
  type        = string
  default     = "falco-prow-test-infra-oci"
}

variable "oke_cluster_ocid" {
  description = "OKE cluster OCID authorized for the autoscaler workload identity. Leave null only before the cluster exists or when no autoscaler is required."
  type        = string
  default     = null

  validation {
    condition     = var.oke_cluster_ocid == null || can(regex("^ocid1\\.cluster\\.[a-z0-9]+\\.[a-z0-9-]+\\.[a-zA-Z0-9._-]+$", var.oke_cluster_ocid))
    error_message = "Provide an OKE cluster OCID or null before initial cluster creation."
  }
}

variable "prow_logs_bucket_name" {
  description = "Prow log bucket authorized by the IAM policy. Must match the platform stack."
  type        = string
  default     = "falco-prow-logs"
}

variable "tags" {
  description = "Freeform tags applied to bootstrap-managed OCI resources."
  type        = map(string)
  default = {
    project   = "falco"
    component = "test-infra"
    managedBy = "terraform"
    scope     = "bootstrap"
  }
}

variable "github_oidc_client_id" {
  description = "Client ID of the manually managed, non-administrative OAuth application for GitHub token exchange. Never supply the client secret."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.github_oidc_client_id))
    error_message = "Provide the OAuth application's non-secret client ID."
  }
}

variable "github_oidc_enabled" {
  description = "Enable GitHub token exchange after a maintainer has reviewed the trust and IAM grants."
  type        = bool
  default     = false
}
