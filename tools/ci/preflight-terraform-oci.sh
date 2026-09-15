#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set +x
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

for required in OCI_OIDC_DOMAIN_URL OCI_OIDC_CLIENT_ID STATE_BACKEND PLATFORM_VARIABLES; do
  [[ -n "${!required:-}" ]] || fail "Missing OCI Terraform prerequisite: $required"
done

jq -e 'type == "object" and (keys == ["bucket","key","namespace","region"])
  and all(.[]; type == "string" and length > 0)
  and .region == "eu-frankfurt-1"' <<< "$STATE_BACKEND" >/dev/null 2>&1 \
  || fail 'Invalid OCI Terraform backend configuration.'
jq -e 'type == "object" and .region == "eu-frankfurt-1"
  and all(.tenancy_ocid,.compartment_ocid,.object_storage_namespace,.terraform_state_bucket_name,.cluster_name,.control_plane_k8s_version,.nodepool_k8s_version; type == "string" and length > 0)
  and (.node_pools | type == "object" and length > 0)
  and (.kubernetes_api_allowed_cidrs | type == "array")
  and (.allow_dynamic_node_images // false) == false
  and all(.node_pool_image_ids.x86,.node_pool_image_ids.arm; type == "string" and startswith("ocid1.image."))' \
  <<< "$PLATFORM_VARIABLES" >/dev/null 2>&1 \
  || fail 'Invalid OCI Terraform production variables.'
[[ "$(jq -r '.bucket' <<< "$STATE_BACKEND")" == "$(jq -r '.terraform_state_bucket_name' <<< "$PLATFORM_VARIABLES")" &&
   "$(jq -r '.namespace' <<< "$STATE_BACKEND")" == "$(jq -r '.object_storage_namespace' <<< "$PLATFORM_VARIABLES")" ]] \
  || fail 'OCI Terraform backend and platform variables refer to different storage.'

case "${GITHUB_EVENT_NAME:-}:${OPERATION:-}" in
  push:) ;;
  workflow_dispatch:verify)
    [[ -z "${PR_NUMBER:-}" && -z "${REVIEWED_SHA:-}" ]] \
      || fail 'Identity verification uses trusted master only; leave PR inputs empty.'
    ;;
  workflow_dispatch:plan)
    [[ "${PR_NUMBER:-}" =~ ^[1-9][0-9]*$ && "${REVIEWED_SHA:-}" =~ ^[0-9a-f]{40}$ ]] \
      || fail 'A valid PR number and exact reviewed head SHA are required.'
    pr=$(gh api "repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER" --jq '[.state,.base.ref,.head.sha] | @tsv')
    IFS=$'\t' read -r state base head <<< "$pr"
    [[ "$state" == open && "$base" == master && "$head" == "$REVIEWED_SHA" ]] \
      || fail 'The PR is not open against master at the reviewed SHA.'
    ;;
  *) fail 'OCI Terraform requires a master push, identity verification or a reviewed PR plan.' ;;
esac

# The workflow checks out current master after acquiring deployment concurrency.
version=$(tr -d '\n\r' < config/clusters/oci/.terraform-version)
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Invalid trusted Terraform version.'
trusted_ref=$(git rev-parse HEAD)
printf 'terraform=%s\ntrusted_ref=%s\n' "$version" "$trusted_ref" >> "${GITHUB_OUTPUT:?}"
