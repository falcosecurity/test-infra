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

function launchConfig(){
  #ALB Ingress and ebs CSI driver
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

  kubectl create configmap plugins --from-file=plugins.yaml=./config/plugins.yaml || true
  kubectl create configmap config --from-file "./config/config.yaml" || true
  kubectl create configmap job-config --from-file "./config/jobs/config.yaml" || true
  kubectl create configmap branding --from-file "./config/branding" || true
  kubectl create secret generic s3-credentials --from-literal=service-account.json="$(./tools/1password.sh -d config/prow/service-account.json)" || true

  #Github related items
  kubectl create secret generic hmac-token --from-literal=hmac="$(./tools/1password.sh -d config/prow/hmac-token)" || true
  kubectl create secret generic oauth-token --from-literal=oauth="$(./tools/1password.sh -d config/prow/oauth-token)" || true
  
  # Related to OAuth setup... need to setup base url on Github for callback before we can create these
  
  # kubectl create secret generic github-oauth-config --from-file=secret="$(./tools/1password.sh -d config/prow/github-oauth-config)" || true
  # kubectl create secret generic cookie --from-file=secret="$(./tools/1password.sh -d config/prow/cookie)" || true
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