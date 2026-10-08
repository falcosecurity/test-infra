# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20261008-e012f2883
prow_commit=e012f2883b7981ab636b0abf3009f0f7064658b1
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:v20261008-e012f2883@sha256:27f4661a3ec34ae12750b78281db7b037fd985d1038cd7598939be9efd15d0d5"

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
