#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 The Falco Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

# Specific to Prow instance
CLUSTER="falco-prow"
ZONE="eu-west-1"

function main() {
  echo "Getting Kubeconfig for cluster access" 
  updateKubeConfig
  echo "Launching Configmaps, and prereq software" 
  launchConfig
  echo "Launching Prow microservices" 
  launchProw
  echo "All done!"
}

function updateKubeConfig() {
  aws eks --region ${ZONE} update-kubeconfig --name ${CLUSTER}-test-infra
}

function launchPodIdentityWebhook() {
  # Create the namespace.
  kubectl apply -f "config/prow/aws/manifests/pod-identity-webhook/namespace.yaml"
  # Apply the other manifests.
  kubectl apply -f "config/prow/aws/manifests/pod-identity-webhook/"
}

function launchMetricsServer() {
  # Metrics Server
  local metrics_server_version="v0.4.4"
  kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/${metrics_server_version}/components.yaml"
}

function createConfigMapIfMissing() {
  local name=$1 namespace=$2 existing
  shift 2
  existing=$(kubectl get configmap "$name" -n "$namespace" --ignore-not-found -o name)
  if [[ -z "$existing" ]]; then
    kubectl create configmap "$name" -n "$namespace" "$@"
  fi
}

function launchProwConfig() {
  # config-updater owns existing configuration; deployment only bootstraps missing maps.
  # Never replace a live catalog from a possibly older deployment checkout.
  createConfigMapIfMissing plugins default --from-file=plugins.yaml=./config/prow/aws/plugins.yaml
  createConfigMapIfMissing config default --from-file=./config/prow/aws/config.yaml
  createConfigMapIfMissing config test-pods --from-file=./config/prow/aws/config.yaml
  local job_file
  local job_files=()
  while IFS= read -r -d '' job_file; do
    job_files+=(--from-file="$job_file")
  done < <(git ls-files -z -- 'config/jobs/aws/*.yaml')
  if (( ${#job_files[@]} == 0 )); then
    echo 'The AWS Prow job catalog is empty; refusing to bootstrap it.' >&2
    exit 1
  fi
  createConfigMapIfMissing job-config default "${job_files[@]}"
  createConfigMapIfMissing branding default --from-file=./config/prow/aws/branding
  kubectl create secret generic s3-credentials --from-literal=service-account.json="${PROW_SERVICE_ACCOUNT_JSON}" || true

  #Github related items
  kubectl create secret generic hmac-token --from-literal=hmac="${PROW_HMAC_TOKEN}" || true
  kubectl create secret generic oauth-token --from-literal=oauth="${PROW_OAUTH_TOKEN}" || true
  kubectl create secret generic oauth-token --from-literal=oauth="${PROW_SERVICE_ACCOUNT_JSON}" -n test-pods || true

  # PR Status
  # Those secrets do not appear to exist anymore
  # 
  # kubectl create secret generic github-oauth-config --from-literal=secret=" ... prow-prstatus-github-oauth-app.yaml ..." || true
  # kubectl create secret generic cookie --from-literal=secret=" ... prow-prstatus-cookie-encryption-key.txt ..." || true
  
  # Related to OAuth setup... need to setup base url on Github for callback before we can create these
  
  # kubectl create secret generic github-oauth-config --from-file=secret=" ... config/prow/aws/manifests/github-oauth-config ..." || true
  # kubectl create secret generic cookie --from-file=secret=" ... config/prow/aws/manifests/cookie ..." || true
}

function launchConfig(){
  launchMetricsServer
  launchPodIdentityWebhook
  kubectl apply -f config/prow/aws/manifests/test_pod_namespace.yaml
  launchProwConfig
}

function launchProwjobCRD(){
  # Apply the prow CRD.
  kubectl apply --server-side=true -f config/prow/aws/manifests/prowjob-crd/prowjob_custromresourcedefinition.yaml
}

function launchProw(){
  kubectl apply -f config/prow/aws/manifests/
}

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup
