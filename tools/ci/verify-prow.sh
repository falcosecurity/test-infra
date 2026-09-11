#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Validate OCI Prow configuration and its separate job catalog, without cloud access.
set -euo pipefail
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
source tools/ci/prow-version.sh
assert_prow_version
validation_dir=$(mktemp -d "${TMPDIR:-/tmp}/falco-ci-prow.XXXXXXXX")
trap 'rm -rf -- "$validation_dir"' EXIT

yq -er '.data."config.yaml"' config/prow/oci/config.yaml > "$validation_dir/config.yaml"
yq -er '.data."plugins.yaml"' config/prow/oci/plugins.yaml > "$validation_dir/plugins.yaml"
check_args=(--config-path="$validation_dir/config.yaml" --plugin-config="$validation_dir/plugins.yaml"
  --warnings=unknown-fields-all --warnings=valid-decoration-config --strict)
# No OCI catalog is created here. Validate its YAML when migration PRs add it.
if [[ -d config/jobs/oci ]]; then
  mkdir -p "$validation_dir/jobs"
  git ls-files -z --cached --others --exclude-standard -- 'config/jobs/oci/*.yaml' 'config/jobs/oci/*.yml' > "$validation_dir/job-files"
  while IFS= read -r -d '' job; do
    destination="$validation_dir/jobs/${job#config/jobs/oci/}"
    mkdir -p "$(dirname "$destination")"
    cp "$job" "$destination"
  done < "$validation_dir/job-files"
  check_args+=(--job-config-path="$validation_dir/jobs")
fi
if [[ -n "${CHECKCONFIG_BIN:-}" && "${CI:-}" != true ]]; then
  "$CHECKCONFIG_BIN" "${check_args[@]}"
else
  # mktemp directories are private to the runner user; keep that UID in the container.
  docker run --rm --network=none --read-only --cap-drop=ALL --security-opt=no-new-privileges \
    --user "$(id -u):$(id -g)" \
    --mount "type=bind,src=$validation_dir,dst=$validation_dir,readonly" \
    "$checkconfig_image" "${check_args[@]}"
fi
