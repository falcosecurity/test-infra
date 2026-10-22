# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20261022-def2183c3
prow_commit=def2183c3b4b4e530347d50b8a13ee65d2cb09f6
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:v20261022-def2183c3@sha256:6e56028a788d9063e6e7af1be67996a801b140e1fb6466cfbfbe72a8e8a2a274"

assert_prow_version() {
  local images image
  images=$(git grep -hoE "us-docker\.pkg\.dev/k8s-infra-prow/images/[a-z0-9-]+:[^[:space:]\"']+" \
    -- 'config/prow/oci/*.yaml' 'config/jobs/oci/*.yaml') || return 1
  for image in $images "$checkconfig_image"; do
    [[ "$image" =~ ^us-docker\.pkg\.dev/k8s-infra-prow/images/[a-z0-9-]+:$prow_version@sha256:[a-f0-9]{64}$ ]] || {
      echo 'OCI Prow images and validation pins must use one digest-pinned release.' >&2
      return 1
    }
  done
}
