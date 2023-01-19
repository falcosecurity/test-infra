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

function createCluster() {
  echo "Creating cluster '${CLUSTER}' (this may take a few minutes)..."
  echo

  pushd config/clusters

  terraform init
  terraform get
  terraform validate

  terraform apply -var-file prow.tfvars -auto-approve
  
  popd

  aws eks --region ${ZONE} update-kubeconfig --name falco-prow-test-infra
}

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup
