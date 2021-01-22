#!/usr/bin/env bash
set -eo pipefail
set -o errexit

export PULL_PULL_SHA=$PULL_PULL_SHA

echo "******************************************************"
echo "DryRun of updating job configs for GitHub PR hash $PULL_PULL_SHA"
echo "******************************************************"

# Using prowjob elements:
# decorate: true
# Will pull in the PR git HASH into the image via the Initupload Sidecar

export GOPATH="/home/prow/go"
export KUBECONFIG="/root/.kube/config"

cd /home/prow/go/src/github.com/falcosecurity/test-infra/prow/update-jobs

echo "******************************************************"
echo "Building update-jobs"
echo "******************************************************"

make build

echo "******************************************************"
echo "Adding EKS value to kubeconfig"
echo "******************************************************"

aws eks --region eu-west-1 update-kubeconfig --name falco-prow-test-infra

echo "******************************************************"
echo "Running job update"
echo "******************************************************"

bin/update-jobs --kubeconfig $KUBECONFIG --jobs-config-path /home/prow/go/src/github.com/falcosecurity/test-infra/config/jobs

echo "******************************************************"
echo "Updated-jobs image"
echo "******************************************************"

exit 0