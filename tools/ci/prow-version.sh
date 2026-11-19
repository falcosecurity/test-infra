# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20261118-9c8eff7c9
prow_commit=9c8eff7c98cc979e833369aefe5d1e86afcf063f
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:v20261118-9c8eff7c9@sha256:5b8d0f41cdc5eb7b91917e3fc3465210a5a91b5b8beae08ca10a40d4d0a3cc3a"

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
