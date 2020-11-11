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
  echo "Deleting Cluster" 
  deleteCluster
}

function terraform-install() {
  [[ -f /usr/local/bin/terraform ]] && echo "`/usr/local/bin/terraform version` already installed at /usr/local/bin/terraform" && return 0
  LATEST_URL=$(curl -sL https://releases.hashicorp.com/terraform/index.json |
    jq -r '.versions[].builds[].url | select(.|test("alpha|beta|rc")|not) | select(.|contains("linux_amd64"))' |
    sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n |
    tail -n1)
  curl ${LATEST_URL} > terraform.zip
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

function deleteCluster() {
  echo "Deleting cluster '${CLUSTER}' (this may take a few minutes)..."
  echo
  terraform init config/clusters
  terraform get
  terraform validate config/clusters
  terraform destroy -var-file config/clusters/prow.tfvars -auto-approve config/clusters
  terraform init -force-copy config/clusters
}

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup