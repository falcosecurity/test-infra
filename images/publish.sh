#!/usr/bin/env bash

set -e

source utils.sh

start_docker

aws_auth

readonly SOURCES_DIR=$1

if [[ -z "${SOURCES_DIR}" ]]; then
    usage
fi

echo "using ${SOURCES_DIR} to build the image"

make -C "${SOURCES_DIR}" build-push

printf '=%.0s' {1..80}; echo
echo "Pushing image to ECR: Success"
