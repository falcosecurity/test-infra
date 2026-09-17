#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set +x
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

check_pull_request() {
  [[ "${PR_NUMBER:-}" =~ ^[1-9][0-9]*$ && "${REVIEWED_SHA:-}" =~ ^[0-9a-f]{40}$ ]] \
    || fail 'A valid PR number and exact reviewed head SHA are required.'
  local pr merge parents attempt
  # GitHub can briefly return null while computing the test merge commit.
  for attempt in 1 2 3; do
    pr=$(gh api "repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER")
    [[ "$(jq -r .mergeable <<< "$pr")" != null ]] && break
    sleep 2
  done
  jq -e --arg head "$REVIEWED_SHA" --arg repo "$GITHUB_REPOSITORY" '
    .state == "open" and .base.ref == "master" and .base.repo.full_name == $repo
    and .head.sha == $head and .mergeable == true
    and (.base.sha | test("^[0-9a-f]{40}$"))
    and (.merge_commit_sha | test("^[0-9a-f]{40}$"))' <<< "$pr" >/dev/null \
    || fail 'The PR must be open, mergeable and target master at the exact reviewed SHA.'
  merge=$(jq -r .merge_commit_sha <<< "$pr")
  parents=$(gh api "repos/$GITHUB_REPOSITORY/git/commits/$merge" --jq '[.parents[].sha] | join(" ")')
  [[ "$parents" == "$(jq -r .base.sha <<< "$pr") $REVIEWED_SHA" ]] \
    || fail 'The PR merge commit does not match its base and head.'
  if [[ "${1:-}" == recheck ]]; then
    [[ "$(jq -r .base.sha <<< "$pr")" == "$BASE_SHA" && "$merge" == "$PLAN_REF" &&
       "$(gh api "repos/$GITHUB_REPOSITORY/git/ref/heads/master" --jq .object.sha)" == "$BASE_SHA" ]] \
      || fail 'The PR or master changed after approval was requested; start a new plan.'
  else
    [[ "$(jq -r .base.sha <<< "$pr")" == "$trusted_ref" ]] \
      || fail 'Master changed during preflight; start a new plan.'
    printf 'ref=%s\nbase_sha=%s\nhead_sha=%s\n' "$merge" "$trusted_ref" "$REVIEWED_SHA" >> "$GITHUB_OUTPUT"
    printf '### OCI Terraform approval\n\nPR #%s, head `%s`, base `%s`, merge `%s`.\n' \
      "$PR_NUMBER" "$REVIEWED_SHA" "$trusted_ref" "$merge" >> "$GITHUB_STEP_SUMMARY"
  fi
  gh api "repos/$GITHUB_REPOSITORY/environments/oci-terraform-plan" \
    | jq -e '.can_admins_bypass == false and any(.protection_rules[]?;
        .type == "required_reviewers" and .prevent_self_review == true and (.reviewers | length) > 0)' >/dev/null \
    || fail 'oci-terraform-plan requires reviewers, prevention of self-review and disabled admin bypass.'
}

if [[ "${1:-}" == recheck ]]; then
  check_pull_request recheck
  exit 0
fi

# Master is resolved after acquiring deployment concurrency, never from PR code.
version=$(tr -d '\n\r' < config/clusters/oci/.terraform-version)
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Invalid trusted Terraform version.'
trusted_ref=$(git rev-parse HEAD)
printf 'terraform=%s\ntrusted_ref=%s\nref=%s\n' "$version" "$trusted_ref" "$trusted_ref" >> "${GITHUB_OUTPUT:?}"

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
  workflow_dispatch:plan|pull_request_target:) check_pull_request ;;
  *) fail 'OCI Terraform requires a master push, identity verification or a reviewed PR plan.' ;;
esac
