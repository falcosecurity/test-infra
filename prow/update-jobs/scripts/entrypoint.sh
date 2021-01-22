#!/usr/bin/env bash
set -eo pipefail
set -o errexit

echo "******************************************************"
echo "DryRun of updating job configs for github PR hash $PULL_PULL_SHA"
echo "******************************************************"

export PULL_PULL_SHA=$PULL_PULL_SHA

# Using prowjob elements:
# decorate: true
# Will pull in the PR git HASH into the image via the Initupload Sidecar

echo "******************************************************"
echo "Running $(basename $@)"
echo "******************************************************"

exec $@
