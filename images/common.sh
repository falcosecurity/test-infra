#!/usr/bin/env bash

usage () {
    echo "Usage: \$ ${BASH_SOURCE[1]} /path/to/image"
    exit 1
}

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

function aws_auth() {
    echo "Logging into AWS ECR..."
    printf '=%.0s' {1..80}; echo
    # If we have opted in to docker in docker, start the docker daemon,
    aws ecr get-login-password --region eu-west-1 \
        | docker login \
            --password-stdin \
            --username AWS \
            292999226676.dkr.ecr.eu-west-1.amazonaws.com
    local WAIT_N=0
    local MAX_WAIT=5
    while true; do
        # aws ecr describe image should only work if the auth is working
        aws ecr describe-images --repository-name test-infra/docker-dind --max-items 1 > /dev/null 2>&1 && break
        if [[ ${WAIT_N} -lt ${MAX_WAIT} ]]; then
            WAIT_N=$((WAIT_N+1))
            echo "Waiting for aws auth to work to be ready, sleeping for ${WAIT_N} seconds."
            sleep ${WAIT_N}
        else
            echo "Reached maximum attempts, not waiting any longer..."
            exit 1
        fi
    done
    printf '=%.0s' {1..80}; echo
    echo "Done setting up aws ecr auth"
}
