#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  echo 'This installer targets the Linux amd64 CI runner. Locally, use the documented native tools.' >&2
  exit 1
}
ci_bin="${RUNNER_TEMP:?}/falco-ci-bin"
download_dir=$(mktemp -d "${RUNNER_TEMP}/falco-ci-download.XXXXXXXX")
trap 'rm -rf -- "$download_dir"' EXIT
mkdir -p "$ci_bin"

download() {
  local url=$1 digest=$2 output=$3
  curl --fail --silent --show-error --location --retry 3 "$url" --output "$output"
  echo "$digest  $output" | sha256sum --check --status
}

download 'https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-amd64.tar.gz' \
  9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883 "$download_dir/kubeconform.tgz"
tar -xzf "$download_dir/kubeconform.tgz" -C "$ci_bin" kubeconform
download 'https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.7.1/kustomize_v5.7.1_linux_amd64.tar.gz' \
  ea375e7372f9aa029129d4b2d16c66b7750b7f1213c4f66f910d981c895818d8 "$download_dir/kustomize.tgz"
tar -xzf "$download_dir/kustomize.tgz" -C "$ci_bin" kustomize
download 'https://github.com/mikefarah/yq/releases/download/v4.52.4/yq_linux_amd64' \
  0c4d965ea944b64b8fddaf7f27779ee3034e5693263786506ccd1c120f184e8c "$ci_bin/yq"
chmod +x "$ci_bin/yq"
download 'https://get.helm.sh/helm-v4.0.4-linux-amd64.tar.gz' \
  29454bc351f4433e66c00f5d37841627cbbcc02e4c70a6d796529d355237671c "$download_dir/helm.tgz"
tar -xzf "$download_dir/helm.tgz" -C "$ci_bin" --strip-components=1 linux-amd64/helm
download 'https://raw.githubusercontent.com/yannh/kubeconform/v0.8.0/scripts/openapi2jsonschema.py' \
  d145babfbb765004030764e1b4e518bfb7a4bd7f111691a08fa57983b81881f3 "$ci_bin/openapi2jsonschema.py"

python3 -m venv "${RUNNER_TEMP}/falco-ci-python"
"${RUNNER_TEMP}/falco-ci-python/bin/pip" install --disable-pip-version-check 'PyYAML==6.0.3'
echo "$ci_bin" >> "${GITHUB_PATH:?}"
echo "${RUNNER_TEMP}/falco-ci-python/bin" >> "$GITHUB_PATH"
