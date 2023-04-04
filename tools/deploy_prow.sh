#!/usr/bin/env bash

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
  echo "Launching Prow monitoring"
  launchMonitoring
  echo "Launching Actions Runner Controller"
  launchARC
  echo "All done!"
}

function updateKubeConfig() {
  aws eks --region ${ZONE} update-kubeconfig --name ${CLUSTER}-test-infra
}

function launchInfraConfig() {
  #ALB Ingress and ebs CSI driver
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/arm64/?ref=release-0.9"

  # Metrics Server
  local metrics_server_version="v0.4.4"
  kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/${metrics_server_version}/components.yaml"
}

function launchProwConfig() {
  kubectl create configmap plugins --from-file=plugins.yaml=./config/plugins.yaml || true
  kubectl create configmap config --from-file "./config/config.yaml" || true
  kubectl create configmap config --from-file "./config/config.yaml" -n test-pods || true
  kubectl create configmap job-config --from-file "./config/jobs/config.yaml" || true
  kubectl create configmap branding --from-file "./config/branding" || true
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
  
  # kubectl create secret generic github-oauth-config --from-file=secret=" ... config/prow/github-oauth-config ..." || true
  # kubectl create secret generic cookie --from-file=secret=" ... config/prow/cookie ..." || true
}

function launchConfig(){
  launchInfraConfig
  launchProwConfig
}

function launchProw(){
  kubectl apply -f config/prow/
}

function launchMonitoring(){
  make -C config/prow/monitoring
}

function launchARC(){
  kubectl apply -f https://github.com/actions/actions-runner-controller/releases/download/v0.27.1/actions-runner-controller.yaml --server-side --force-conflicts
  kubectl create secret generic controller-manager -n actions-runner-system --from-literal=github_token=${PROW_OAUTH_TOKEN}
  kubectl apply -f config/prow/arc/
}

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup
