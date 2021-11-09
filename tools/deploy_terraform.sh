#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Specific to Prow instance
PROW_INSTANCE_NAME="${PROW_INSTANCE_NAME:-}"
CLUSTER="falco-prow"
ZONE="eu-west-1"

function main() {
  echo "> Installing terraform"
  echo
  terraform-install
  echo "> Running Terraform"
  echo
  createCluster
}

function terraform-install() {
  hash terraform 2>/dev/null && \
    echo "Already installed at $(command -v terraform)." && \
    echo "Version: $(terraform version)" && \
    return 0

  local terraform_version=$(grep required_version config/clusters/terraform_versions.tf | cut -d '=' -f2 | tr -d '"' | tr -d ' ')
  local terraform_url="https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip"
  local install_path="/usr/local/bin/"
  local tmpdir=$(mktemp -d)

  curl -s "${terraform_url}" > $tmpdir/terraform.zip
  unzip $tmpdir/terraform.zip
  rm -rf $tmpdir
  install terraform $install_path
  terraform --version
  echo "Installed: $(terraform)"
}

# Will add this in once we have the need for multiple workspaces (dev/prod or multi account)
# Uses Default workspace until we select one
function createClusterStateBackend() {
  local workspace="test-infra"
  echo "Creating cluster '${CLUSTER}' state backend..."
  terraform init config/clusters
  terraform workspace new $workspace config/clusters || true
  terraform workspace select $workspace config/clusters
}

function createCluster() {
  echo "Creating cluster '${CLUSTER}' (this may take a few minutes)..."
  echo
  terraform init config/clusters
  terraform get
  terraform validate config/clusters

  terraform apply -var-file config/clusters/prow.tfvars -auto-approve config/clusters
  aws eks --region ${ZONE} update-kubeconfig --name falco-prow-test-infra
}

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup
