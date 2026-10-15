# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20261013-b4d923a1a
prow_commit=b4d923a1a60cedd794f9461c529df11ebd8e1abc
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:v20261013-b4d923a1a@sha256:efa715acd95ff646161c708df1d756d53c10193e1de7cf6148087a49b6290a3d"

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
