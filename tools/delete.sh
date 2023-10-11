#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 The Falco Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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


  pushd config/clusters

  terraform init
  terraform get
  terraform validate
  terraform destroy -var-file prow.tfvars -auto-approve
  terraform init -force-copy

  popd
}

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup