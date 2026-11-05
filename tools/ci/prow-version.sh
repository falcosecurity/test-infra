# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20261105-a23969f42
prow_commit=a23969f42bcfccdeb82025ed62b7d0b3c53a9191
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:v20261105-a23969f42@sha256:eeb79c8153505233b4cf9b67ed5590ea97488c94b4271bc772033044d1c7098a"

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
