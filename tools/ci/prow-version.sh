# SPDX-License-Identifier: Apache-2.0
# Shared OCI release pins for manifest and Prow configuration validation.
prow_version=v20260811-cafa49460
prow_commit=cafa494600840c6b58f9b765aa7133ca6e82bb48
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:$prow_version@sha256:0ec431c5efcdee82117fa6d272497ed657fd2bce1b1620acd164e41212fde2f3"

assert_prow_version() {
  local runtime_image
  runtime_image=$(yq -er 'select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.name == "prow-controller-manager") | .image' config/prow/oci/prow-controller-manager.yaml)
  [[ "$runtime_image" == *":$prow_version@sha256:"* ]] || {
    echo 'Update the OCI validation pins to match the Prow deployment.' >&2
    return 1
  }
}
