variable "gitops_github_token" {
  sensitive = true
  type      = string
}

variable "gitops_github_org" {
  type = string
}

variable "gitops_github_repository" {
  description = "The name of the GitHub repository containing the Kubernetes cluster manifests"
  type        = string
}

variable "gitops_github_repository_branch" {
  description = "The branch of the GitHub repository containing the Kubernetes cluster manifests"
  type        = string
  default     = "main"
}

