#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function main() {
  echo "Launching Prow Monitoring stack" 
  launchMonitoring
  echo "All done!"
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

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup
