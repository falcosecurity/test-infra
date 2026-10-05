#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Align validation pins and the vendored CRD after Renovate updates Prow images.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

image=$(sed -nE 's/^[[:space:]]*- image: (us-docker\.pkg\.dev\/k8s-infra-prow\/images\/checkconfig:.*)$/\1/p' config/jobs/oci/check-prow-config/check-prow-config.yaml)
if [[ ! "$image" =~ ^us-docker\.pkg\.dev/k8s-infra-prow/images/checkconfig:(v[0-9]{8}-[a-f0-9]{6,40})@sha256:[a-f0-9]{64}$ ]]; then
  echo 'Expected one digest-pinned OCI checkconfig image.' >&2
  exit 1
fi
version=${BASH_REMATCH[1]}
short_commit=${version#*-}
commit=$(curl --fail --silent --show-error --location --retry 3 \
  "https://api.github.com/repos/kubernetes-sigs/prow/commits/$short_commit" | jq -er '.sha')
[[ "$commit" =~ ^[a-f0-9]{40}$ && "$commit" == "$short_commit"* ]]

sync_dir=$(mktemp -d)
trap 'rm -f -- "$sync_dir/prow-version.sh" "$sync_dir/prowjob-crd.yaml"; rmdir -- "$sync_dir"' EXIT
sed -e "s|^prow_version=.*|prow_version=$version|" \
    -e "s|^prow_commit=.*|prow_commit=$commit|" \
    -e "s|^checkconfig_image=.*|checkconfig_image=\"$image\"|" \
    tools/ci/prow-version.sh > "$sync_dir/prow-version.sh"
source "$sync_dir/prow-version.sh"
assert_prow_version
curl --fail --silent --show-error --location --retry 3 \
  "https://raw.githubusercontent.com/kubernetes-sigs/prow/$commit/config/prow/cluster/prowjob-crd/prowjob_customresourcedefinition.yaml" \
  --output "$sync_dir/prowjob-crd.yaml"
grep -qx 'kind: CustomResourceDefinition' "$sync_dir/prowjob-crd.yaml"
cp "$sync_dir/prow-version.sh" tools/ci/prow-version.sh
cp "$sync_dir/prowjob-crd.yaml" config/prow/oci/prowjob-crd.yaml
