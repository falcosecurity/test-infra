#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
export TFENV_TERRAFORM_VERSION
TFENV_TERRAFORM_VERSION=$(tr -d '\n\r' < config/clusters/oci/.terraform-version)
[[ "$TFENV_TERRAFORM_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]

validation_dir=$(mktemp -d "${TMPDIR:-/tmp}/falco-ci-terraform.XXXXXXXX")
trap 'rm -rf -- "$validation_dir"' EXIT
# No tfvars, state, backend configuration files, credentials or bootstrap files.
cp config/clusters/oci/*.tf config/clusters/oci/.terraform.lock.hcl "$validation_dir/"
terraform -chdir="$validation_dir" fmt -check
terraform -chdir="$validation_dir" init -backend=false -input=false -lockfile=readonly
terraform -chdir="$validation_dir" validate -no-color
