#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Specific to Prow instance
PROW_INSTANCE_NAME="${PROW_INSTANCE_NAME:-}"
CLUSTER="falco-prow"
S3_BUCKET="falco-prow-logs"
ZONE="us-west-2"

function main() {
  echo "Creating storageBucket" 
  storageBucket
  echo "Creating Cluster" 
  createCluster
  echo "Launching Configmaps, and prereq software" 
  launchConfig
  echo "All done!"
}

#Create Bucket of out band so don't lose data in case of cluster or terrform down
function storageBucket() {
  echo "Checking for S3 Bucket '${S3_BUCKET}' for prow storage (this may take a few seconds)..."
  BUCKET_EXISTS=$(aws s3api head-bucket --bucket $S3_BUCKET 2>&1 || true)
  if [ -z "$BUCKET_EXISTS" ]; then
    echo "Bucket already exists skipping...."
  else
    echo "Bucket does not exist creating now....."
    aws s3 mb s3://$S3_BUCKET
  fi
}

function createCluster() {
  echo "Creating cluster '${CLUSTER}' (this may take a few minutes)..."
  echo
	terraform init config/clusters
	terraform get
	terraform validate config/clusters
	terraform apply -var-file config/clusters/prow.tfvars -auto-approve config/clusters
	terraform init -force-copy config/clusters
  aws eks --region us-west-2 update-kubeconfig --name falco-prow-test-infra
}

function launchConfig(){
  #ALB Ingress and ebs CSI driver
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"
  kubectl apply -f "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.8/docs/examples/rbac-role.yaml"

  kubectl create configmap plugins --from-file=plugins.yaml=./config/plugins.yaml
  kubectl create configmap config --from-file "./config/config.yaml"
  kubectl create configmap job-config --from-file "./config/jobs/config.yaml"
  kubectl create configmap branding --from-file "./config/branding"
  kubectl create secret generic s3-credentials --from-file=service-account.json=./config/prow/service-account.json

  #Github related items
  kubectl create secret generic hmac-token --from-file=hmac=./config/prow/hmac-token
  kubectl create secret generic oauth-token --from-file=oauth=./config/prow/oauth-token
  kubectl create secret generic github-oauth-config --from-file=secret=./config/prow/github_oauth
  kubectl create secret generic cookie --from-file=secret=./config/prow/cookie.txt
}

# function launchProw(){
# }

function cleanup() {
  returnCode="$?"
  exit "${returnCode}"
}

trap cleanup EXIT
main "$@"
cleanup