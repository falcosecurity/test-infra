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
# ENSURE_DOCKER: whether to ensure Docker daemon running
# DBG_MAKE_BUILD_TARGET: specify the makefile target

# Needed Bash >= 4.0
declare -A DBG_FILTERS
DBG_FILTERS['--target-distro']="${1}"
DBG_FILTERS['--target-kernelrelease']="${2}"
DBG_FILTERS['--target-kernelversion']="${3}"

DBG_MAKE_BUILD_OPTIONS=""
DBG_MAKE_BUILD_TARGET="${DBG_MAKE_BUILD_TARGET:-"build"}" # build or validate

PUBLISH_S3="${PUBLISH_S3:-false}"
ENSURE_DOCKER="${ENSURE_DOCKER:-true}"

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

function build_and_publish() {
	test "${ENSURE_DOCKER}" == "true" && start_docker

	for filter_key in "${!DBG_FILTERS[@]}"; do
		test -z "${DBG_FILTERS[$filter_key]}" \
			|| DBG_MAKE_BUILD_OPTIONS="${DBG_MAKE_BUILD_OPTIONS} ${filter_key}=${DBG_FILTERS[$filter_key]}"
	done

	# when building, ignore errors (just report them back to driverkit/output/failing.log)
	DBG_MAKE_BUILD_OPTIONS="${DBG_MAKE_BUILD_OPTIONS} --ignore-errors --skip-existing --redirect-errors=driverkit/output/failing.log"
	# If requested, publish too!
	test "${PUBLISH_S3}" == "true" && DBG_MAKE_BUILD_OPTIONS="${DBG_MAKE_BUILD_OPTIONS} --publish"
	dbg-go configs build $DBG_MAKE_BUILD_OPTIONS

	pretty_echo "dbg-go build complete"
}

function validate() {
	dbg-go configs validate --architecture arm64
	dbg-go configs validate --architecture amd64

	pretty_echo "dbg-go validation complete"
}

function main() {
	pretty_echo "Running dbg-go with target $DBG_MAKE_BUILD_TARGET..."
	if [[ "$DBG_MAKE_BUILD_TARGET" = "build" ]]; then
		build_and_publish
	else
		validate
	fi
	exit 0
}

main
