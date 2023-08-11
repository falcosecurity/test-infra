# Unfortunately the flux provider for bootsrap, needs
# the configuration for the specific cluster to install Flux to.
# Legacy modules which use their own local providers like this,
# do not support for_each.

provider "github" {
  owner = var.gitops_github_org
  token = var.gitops_github_token
}

resource "tls_private_key" "flux_prow" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "flux_prow" {
  title      = "prow-gitops"
  repository = var.gitops_github_repository
  key        = tls_private_key.flux_prow.public_key_openssh
  read_only  = "false"
}

provider "flux" {
  alias = "prow"

  kubernetes = {
    config_path = module.eks.kubeconfig_filename
  }

  git = {
    url    = "ssh://git@github.com/${var.gitops_github_org}/${var.gitops_github_repository}.git"
    branch = var.gitops_github_repository_branch
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux_prow.private_key_pem
    }
  }
}

resource "flux_bootstrap_git" "prow" {
  depends_on = [github_repository_deploy_key.flux_prow]

  provider = flux.prow

  network_policy = false

  components = [
    "source-controller",
    "kustomize-controller",
    "helm-controller",
    "notification-controller",
  ]

  components_extra = [
    "image-reflector-controller",
    "image-automation-controller",
  ]

  path = "config/kubernetes"

  version = "v2.0.1"
}

