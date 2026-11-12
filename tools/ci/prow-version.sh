# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20261107-d4aa52fd2
prow_commit=d4aa52fd2fbd8e50537f65866fe8272fbabf4eab
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:v20261107-d4aa52fd2@sha256:220c7e2c76d7314b049fffddf99ca2e6ff38387960d604e9ea56c429615d1906"

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
