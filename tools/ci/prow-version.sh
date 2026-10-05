# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20260811-cafa49460
prow_commit=cafa494600840c6b58f9b765aa7133ca6e82bb48
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:$prow_version@sha256:0ec431c5efcdee82117fa6d272497ed657fd2bce1b1620acd164e41212fde2f3"

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
