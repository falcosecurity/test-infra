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

  local terraform_version=$(grep required_version config/clusters/terraform_versions.tf | cut -d '=' -f3 | tr -d '"' | tr -d ' ')
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
