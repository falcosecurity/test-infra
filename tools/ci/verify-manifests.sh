#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
cloud=${1:?Usage: bash tools/ci/verify-manifests.sh aws|oci}
[[ "$cloud" == aws || "$cloud" == oci ]] || exit 1
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
validation_dir=$(mktemp -d "${TMPDIR:-/tmp}/falco-ci-manifests.XXXXXXXX")
trap 'rm -rf -- "$validation_dir"' EXIT
mkdir -p "$validation_dir/schemas"

# Helm is used only for local rendering; do not load local cluster/registry credentials.
export KUBECONFIG=/dev/null
export HELM_CONFIG_HOME="$validation_dir/helm/config"
export HELM_CACHE_HOME="$validation_dir/helm/cache"
export HELM_DATA_HOME="$validation_dir/helm/data"
export HELM_REGISTRY_CONFIG="$validation_dir/helm/registry.json"
kube_version=1.35.0
converter=${OPENAPI2JSONSCHEMA:-$(dirname "$(command -v kubeconform)")/openapi2jsonschema.py}

extract_crds() {
  yq --exit-status 'select(.kind == "CustomResourceDefinition")' "$validation_dir/chart.yaml" >> "$validation_dir/crds.yaml"
  echo '---' >> "$validation_dir/crds.yaml"
}

if [[ "$cloud" == aws ]]; then bootstrap=tools/deploy_argocd.sh; else bootstrap=tools/deploy_argocd_oci.sh; fi
argo_version=$(sed -n 's/^CHART_VERSION="\([^"]*\)".*/\1/p' "$bootstrap")
[[ "$argo_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
helm template schema argo-cd --repo https://argoproj.github.io/argo-helm --version "$argo_version" \
  --include-crds --skip-tests --kube-version "$kube_version" > "$validation_dir/chart.yaml"
extract_crds

if [[ "$cloud" == oci ]]; then
  for application in cert-manager envoy-gateway-crds falco-operator prometheus-operator-crds; do
    source_file="config/applications/oci/$application.yaml"
    chart=$(yq -er '.spec.source.chart' "$source_file")
    repository=$(yq -er '.spec.source.repoURL' "$source_file")
    version=$(yq -er '.spec.source.targetRevision' "$source_file")
    yq -r '.spec.source.helm.values // "{}"' "$source_file" > "$validation_dir/values.yaml"
    chart_args=("$chart" --repo "$repository")
    if [[ "$repository" != https://* ]]; then chart_args=("oci://$repository/$chart"); fi
    helm template schema "${chart_args[@]}" --version "$version" --include-crds --skip-tests \
      --kube-version "$kube_version" --values "$validation_dir/values.yaml" > "$validation_dir/chart.yaml"
    extract_crds
  done
fi
(
  cd "$validation_dir/schemas"
  DENY_ROOT_ADDITIONAL_PROPERTIES=1 FILENAME_FORMAT='{fullgroup}_{kind}_{version}' python3 "$converter" "$validation_dir/crds.yaml"
)
schema_args=(-schema-location default -schema-location "$validation_dir/schemas/{{ .Group }}_{{ .ResourceKind }}_{{ .ResourceAPIVersion }}.json")

if [[ "$cloud" == aws ]]; then
  # Retain the existing AWS schema policy; do not silently impose OCI's API contract.
  kubeconform -summary -ignore-filename-pattern '\.json$' -ignore-missing-schemas config/prow/aws/manifests/
  kubeconform -strict -summary "${schema_args[@]}" config/applications/aws/
  exit
fi

prow_version=v20260811-cafa49460
prow_commit=cafa494600840c6b58f9b765aa7133ca6e82bb48
checkconfig_image="us-docker.pkg.dev/k8s-infra-prow/images/checkconfig:$prow_version@sha256:0ec431c5efcdee82117fa6d272497ed657fd2bce1b1620acd164e41212fde2f3"
curl --fail --silent --show-error --location --retry 3 \
  "https://raw.githubusercontent.com/kubernetes-sigs/prow/$prow_commit/config/prow/cluster/prowjob-crd/prowjob_customresourcedefinition.yaml" \
  --output "$validation_dir/prowjob-crd.yaml"
cmp config/prow/oci/prowjob-crd.yaml "$validation_dir/prowjob-crd.yaml"
runtime_image=$(yq -r 'select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.name == "prow-controller-manager") | .image' config/prow/oci/prow-controller-manager.yaml)
[[ "$runtime_image" == *":$prow_version@sha256:"* ]] || {
  echo 'Update the OCI checkconfig pin to match the Prow deployment.' >&2; exit 1;
}

git ls-files -z --cached --others --exclude-standard -- 'config/prow/oci/*.yaml' 'config/applications/oci/*.yaml' > "$validation_dir/source-files"
manifest_files=()
while IFS= read -r -d '' manifest; do
  case "$manifest" in */kustomization.yaml|*/argocd-values.yaml) continue ;; esac
  manifest_files+=("$manifest")
done < "$validation_dir/source-files"
(( ${#manifest_files[@]} > 0 ))
# The only repository CRD is checked byte-for-byte against the pinned upstream source.
crd_names=$(yq -r 'select(.kind == "CustomResourceDefinition") | .metadata.name' "${manifest_files[@]}")
[[ "$crd_names" == prowjobs.prow.k8s.io ]] || { echo 'Unexpected repository CRD: add explicit validation before including it.' >&2; exit 1; }
kubeconform -strict -summary -kubernetes-version "$kube_version" -skip CustomResourceDefinition "${schema_args[@]}" "${manifest_files[@]}"
kustomize build config/prow/oci > "$validation_dir/rendered.yaml"
kubeconform -strict -summary -kubernetes-version "$kube_version" -skip CustomResourceDefinition "${schema_args[@]}" "$validation_dir/rendered.yaml"

yq -er '.data."config.yaml"' config/prow/oci/config.yaml > "$validation_dir/config.yaml"
yq -er '.data."plugins.yaml"' config/prow/oci/plugins.yaml > "$validation_dir/plugins.yaml"
check_args=(--config-path="$validation_dir/config.yaml" --plugin-config="$validation_dir/plugins.yaml"
  --warnings=unknown-fields-all --warnings=valid-decoration-config --strict)
# No OCI catalog is created here. Validate its YAML when migration PRs add it.
if [[ -d config/jobs/oci ]]; then
  mkdir -p "$validation_dir/jobs"
  git ls-files -z --cached --others --exclude-standard -- 'config/jobs/oci/*.yaml' > "$validation_dir/job-files"
  while IFS= read -r -d '' job; do
    destination="$validation_dir/jobs/${job#config/jobs/oci/}"
    mkdir -p "$(dirname "$destination")"
    cp "$job" "$destination"
  done < "$validation_dir/job-files"
  check_args+=(--job-config-path="$validation_dir/jobs")
fi
if [[ -n "${CHECKCONFIG_BIN:-}" && "${CI:-}" != true ]]; then
  "$CHECKCONFIG_BIN" "${check_args[@]}"
else
  # mktemp directories are private to the runner user; keep that UID in the container.
  docker run --rm --network=none --read-only --cap-drop=ALL --security-opt=no-new-privileges \
    --user "$(id -u):$(id -g)" \
    --mount "type=bind,src=$validation_dir,dst=$validation_dir,readonly" \
    "$checkconfig_image" "${check_args[@]}"
fi
