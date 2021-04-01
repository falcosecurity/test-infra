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
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/arm64/?ref=release-0.9"

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
  
  # Related to OAuth setup... need to setup base url on Github for callback before we can create these

  # kubectl create secret generic github-oauth-config --from-file=secret="$(./tools/1password.sh -d config/prow/github-oauth-config)" || true
  # kubectl create secret generic cookie --from-file=secret="$(./tools/1password.sh -d config/prow/cookie)" || true
}


function launchMonitoring(){
  # Requires EBS CSI driver installed, and prow installation to create the storage-class

  # Create monitoring namespace
  kubectl apply -f config/clusters/monitoring/prow_monitoring_namespace.yaml

  # Create Secrets from 1password
  kubectl create secret generic grafana-password --from-literal=grafana-password="$(./tools/1password.sh -d grafana-password)" || true

  # Launch Prometheus CRD's
  kubectl apply -f config/clusters/monitoring/crd/

  # Launch Prometheus
  kubectl apply -f config/clusters/monitoring/prometheus/

  # Launch Prometheus Alertmanager
  kubectl apply -f config/clusters/monitoring/alertmanager/

  # Launch Grafana
  kubectl apply -f config/clusters/monitoring/grafana/
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
