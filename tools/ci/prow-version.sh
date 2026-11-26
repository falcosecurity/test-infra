# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20261124-6f9f58136
prow_commit=6f9f58136ab785e0d1b2597ab5c5154ed642a68f
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:v20261124-6f9f58136@sha256:54d704c63b2a72aef1bfe56e3ce55c299f63c3a2efca41e53bc6991306ac5bc6"

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
