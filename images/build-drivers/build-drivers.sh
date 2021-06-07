#!/usr/bin/env bash
set -eo pipefail
set -o errexit

# Optional positional arguments:
# $1: Linux distribution name
# $2: Kernel version filter as expected by DBG (e.g. "5.*")
# $3: Falco driver version
#
# Environment variables:
# PUBLISH_S3: whether to publish built drivers to S3
# DBG_WORKDIR: the absolute path from where to run DBG
# ENSURE_DOCKER: whether to ensure Docker daemon running

# Needed Bash >= 4.0
declare -A DBG_FILTERS
DBG_FILTERS['TARGET_DISTRO']="${1}"
DBG_FILTERS['TARGET_KERNEL']="${2}"
DBG_FILTERS['TARGET_VERSION']="${3}"
DBG_MAKE_BUILD_OPTIONS=""
DBG_MAKE_BUILD_TARGET="specific_target"
DBG_MAKE_PUBLISH_TARGET="publish_s3"
DBG_WORKDIR="${DBG_WORKDIR:-/home/prow/go/src/github.com/falcosecurity/test-infra/driverkit}"

ENSURE_DOCKER="${ENSURE_DOCKER:-true}"

make="$(command -v make)"

function pretty_echo() {
	echo "******************************************************"
	echo "${1}"
	echo "******************************************************"
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

function build() {
	PUBLISH_S3="${PUBLISH_S3:-false}"
	export PULL_PULL_SHA=$PULL_PULL_SHA
	
	for filter_key in "${!DBG_FILTERS[@]}"; do
		test -z "${DBG_FILTERS[$filter_key]}" \
			|| DBG_MAKE_BUILD_OPTIONS="${DBG_MAKE_BUILD_OPTIONS} -e ${filter_key}=${DBG_FILTERS[$filter_key]}"
	done

	pretty_echo "Testing building Drivers for PR hash $PULL_PULL_SHA"
	
	cd $DBG_WORKDIR
	touch output/failing.log
	DBG_COMMIT=$(git log -1 --format=format:%H --full-diff -- ./)

	pretty_echo "Found current driverkit version DBG_COMMIT $DBG_COMMIT. Running DBG build..."
	
	$make $DBG_MAKE_BUILD_OPTIONS $DBG_MAKE_BUILD_TARGET
	
	pretty_echo "DBG build complete"
}

function publish() {
	pretty_echo "Running DBG publishing..."
	$make $DBG_MAKE_PUBLISH_TARGET
	pretty_echo "DBG publishing complete"
}

function main() {
	test "${ENSURE_DOCKER}" == "true" && start_docker
	build
	test "${PUBLISH_S3}" == "true" && publish
	exit 0
}

main
