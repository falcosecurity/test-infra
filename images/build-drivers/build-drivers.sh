#!/usr/bin/env bash
set -eo pipefail
set -o errexit

function start_docker() {
    echo "Docker in Docker enabled, initializing..."
    printf '=%.0s' {1..80}; echo
    # If we have opted in to docker in docker, start the docker daemon,
    service docker start
    # the service can be started but the docker socket not ready, wait for ready
    local WAIT_N=0
    local MAX_WAIT=20
    while true; do
        # docker ps -q should only work if the daemon is ready
        docker ps -q > /dev/null 2>&1 && break
        if [[ ${WAIT_N} -lt ${MAX_WAIT} ]]; then
            WAIT_N=$((WAIT_N+1))
            echo "Waiting for docker to be ready, sleeping for ${WAIT_N} seconds."
            sleep ${WAIT_N}
        else
            echo "Reached maximum attempts, not waiting any longer..."
            exit 1
        fi
    done
    printf '=%.0s' {1..80}; echo
    echo "Done setting up docker in docker."
}

PUBLISH_S3="${PUBLISH_S3:-false}"
export PULL_PULL_SHA=$PULL_PULL_SHA

echo "******************************************************"
echo "Testing building Drivers for PR hash $PULL_PULL_SHA"
echo "******************************************************"

cd /home/prow/go/src/github.com/falcosecurity/test-infra

touch driverkit/output/failing.log

DRIVERKIT_COMMIT=$(git log -1 --format=format:%H --full-diff -- driverkit/)

echo "******************************************************"
echo "Found current driverkit version DRIVERKIT_COMMIT $DRIVERKIT_COMMIT"
echo "******************************************************"

start_docker

cd driverkit/
make -e TARGET_DISTRO="$1" specific_target

test "${PUBLISH_S3}" == "true" && make publish_s3

echo "******************************************************"
echo "Ran DriverKit tests"
echo "******************************************************"

exit 0
