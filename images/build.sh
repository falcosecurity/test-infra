#!/usr/bin/env bash

set -e

source utils.sh

start_docker

readonly SOURCES_DIR=$1

if [[ -z "${SOURCES_DIR}" ]]; then
    usage
fi

echo "using ${SOURCES_DIR} to build the image"

make -C "${SOURCES_DIR}" build-image

printf '=%.0s' {1..80}; echo
