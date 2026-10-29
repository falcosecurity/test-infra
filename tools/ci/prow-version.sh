# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20261028-c06373a3e
prow_commit=c06373a3e2cdcf0de2a087b4ed1db426366694b8
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:v20261028-c06373a3e@sha256:d45806e0b2ccf975cb98e65cde0c07f05a8c86df80ed64afecd7e22e166fb806"

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
