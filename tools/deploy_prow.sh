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
  kubectl create secret generic s3-credentials --from-literal=service-account.json="$(./tools/1password.sh -d config/prow/service-account.json)" || true

  #Github related items
  kubectl create secret generic hmac-token --from-literal=hmac="$(./tools/1password.sh -d config/prow/hmac-token)" || true
  kubectl create secret generic oauth-token --from-literal=oauth="$(./tools/1password.sh -d config/prow/oauth-token)" || true
  kubectl create secret generic oauth-token --from-literal=oauth="$(./tools/1password.sh -d config/prow/oauth-token)" -n test-pods || true

  # PR Status
  kubectl create secret generic github-oauth-config --from-literal=secret="$(./tools/1password.sh -d prow-prstatus-github-oauth-app.yaml)" || true
  kubectl create secret generic cookie --from-literal=secret="$(./tools/1password.sh -d prow-prstatus-cookie-encryption-key.txt)" || true

  # Cosign
  kubectl create secret generic -n cosign openinfra-oci-sign \
	  --from-literal="cosign.key"="$(./tools/1password.sh -d infra/cosign/key)" \
	  --from-literal="cosign.pub"="$(./tools/1password.sh -d infra/cosign/pub)" \
	  --from-literal="cosign.password"="$(./tools/1password.sh -d infra/cosign/password)" || true
  
  # Related to OAuth setup... need to setup base url on Github for callback before we can create these
  
  # kubectl create secret generic github-oauth-config --from-file=secret="$(./tools/1password.sh -d config/prow/github-oauth-config)" || true
  # kubectl create secret generic cookie --from-file=secret="$(./tools/1password.sh -d config/prow/cookie)" || true
}

function launchConfig(){
  launchInfraConfig
  launchProwConfig
}

function launchProw(){
  kubectl apply -f config/prow/
}

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup
