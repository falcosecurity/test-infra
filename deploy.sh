#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Specific to Prow instance
PROW_INSTANCE_NAME="${PROW_INSTANCE_NAME:-}"
CLUSTER="falco-prow"
ZONE="eu-west-1"

function main() {
  echo "Creating Cluster" 
  createCluster
  echo "Launching Configmaps, and prereq software" 
  launchConfig
  echo "Launching Prow microservices" 
  launchProw
  echo "All done!"
}

function createCluster() {
  echo "Creating cluster '${CLUSTER}' (this may take a few minutes)..."
  echo
  terraform init config/clusters
  terraform get
  terraform validate config/clusters
  terraform apply -var-file config/clusters/prow.tfvars -auto-approve config/clusters
  terraform init -force-copy config/clusters
  aws eks --region ${ZONE} update-kubeconfig --name falco-prow-test-infra
}

function launchConfig(){
  #ALB Ingress and ebs CSI driver
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

  kubectl create configmap plugins --from-file=plugins.yaml=./config/plugins.yaml || true
  kubectl create configmap config --from-file "./config/config.yaml" || true
  kubectl create configmap job-config --from-file "./config/jobs/config.yaml" || true
  kubectl create configmap branding --from-file "./config/branding" || true
  kubectl create secret generic s3-credentials --from-literal=service-account.json="$(./1password.sh -d config/prow/service-account.json)" || true

  #Github related items
  kubectl create secret generic hmac-token --from-literal=hmac="$(./1password.sh -d config/prow/hmac-token)" || true
  kubectl create secret generic oauth-token --from-literal=oauth="$(./1password.sh -d config/prow/oauth-token)" || true
  kubectl create secret generic github-oauth-config --from-file=secret=./config/prow/github_oauth || true
  kubectl create secret generic cookie --from-file=secret=./config/prow/cookie.txt || true
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
