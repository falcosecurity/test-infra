#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Specific to Prow instance
PROW_INSTANCE_NAME="${PROW_INSTANCE_NAME:-}"
CLUSTER="falco-prow"
ZONE="eu-west-1"

function main() {
  echo "installing terraform"
  terraform-install
  echo "Running Terraform"
  createCluster
}

function terraform-install() {
  [[ -f /usr/local/bin/terraform ]] && echo "`/usr/local/bin/terraform version` already installed at /usr/local/bin/terraform" && return 0
  LATEST_URL=$(curl -sL https://releases.hashicorp.com/terraform/index.json |
    jq -r '.versions[].builds[].url | select(.|test("alpha|beta|rc")|not) | select(.|contains("linux_amd64"))' |
    sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n |
    tail -n1)
  STABLE_URL="https://releases.hashicorp.com/terraform/0.13.5/terraform_0.13.5_linux_amd64.zip"
  curl ${STABLE_URL} > terraform.zip
  unzip terraform.zip
  rm -rf terraform.zip
  install terraform /usr/local/bin/
  terraform --version
  echo "Installed: `terraform`"
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

function importEcrRepositoriesToTerraformState() {
  local ecr_repositories="test-infra/update-jobs test-infra/golang test-infra/build-drivers test-infra/docker-dind test-infra/autobump test-infra/arm-build test-infra/build-libs"

  for ecr_repository in $ecr_repositories; do
    echo
    echo "> AWS ECR Repository name: ${ecr_repository}"
    tf_resource="${ecr_repository/test-infra\//}"
    tf_resource="${tf_resource/-/_}"
    echo "  TF Resource Name: ${tf_resource}"

    terraform import aws_ecr_repository.${tf_resource} ${ecr_repository}
  done
}

function createCluster() {
  echo "Creating cluster '${CLUSTER}' (this may take a few minutes)..."
  echo
  terraform init config/clusters
  terraform get
  terraform validate config/clusters

  # TODO: remove this line after ECR Repository resources are correctly imported to Terraform state.
  importEcrRepositoriesToTerraformState

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
