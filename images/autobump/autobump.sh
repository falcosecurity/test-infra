#!/usr/bin/env bash

# Copyright (C) 2021 The Falco Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

# Set this to something more specific if the repo hosts multiple Prow instances.
# Must be a valid to use as part of a git branch name. (e.g. no spaces)
PROW_CONTROLLER_MANAGER_FILE="${PROW_CONTROLLER_MANAGER_FILE:-}"
PROW_INSTANCE_NAME="${PROW_INSTANCE_NAME:-prow}"


# Args from environment (with defaults)
GH_PROXY="${GH_PROXY:-"http://ghproxy"}"
GH_ORG="${GH_ORG:-"falcosecurity"}"
GH_REPO="${GH_REPO:-"test-infra"}"
BOT_NAME="${BOT_NAME:-"poiana"}"
BOT_MAIL="${BOT_MAIL:-"51138685+poiana@users.noreply.github.com"}"
BOT_GPG_KEY_PATH="${BOT_GPG_KEY_PATH:-"/root/gpg-signing-key/poiana.asc"}"
BOT_GPG_PUBLIC_KEY="${BOT_GPG_PUBLIC_KEY:-"5B969CD19422B477E5609F8C900C09B3E21C193F"}"
FORK_GH_REPO="${FORK_GH_REPO:-${GH_REPO}}"

export GIT_COMMITTER_NAME=${BOT_NAME}
export GIT_COMMITTER_EMAIL=${BOT_MAIL}
export GIT_AUTHOR_NAME=${BOT_NAME}
export GIT_AUTHOR_EMAIL=${BOT_MAIL}


# TODO(fejta): rewrite this in a better language REAL SOON  <-lol
main() {
	if [[ $# -lt 1 ]]; then
			echo "Usage: $(basename "$0") <path to github token or http cookiefile> [git-name] [git-email]" >&2
			return 1
	fi
	creds=$1
	shift
	check-args
	ensure-git-config "$@"
	ensure-gpg-keys "$@"
	echo "Bumping ${PROW_INSTANCE_NAME} to upstream (prow.k8s.io) version..." >&2
	/bump.sh --upstream

	cd "$(git rev-parse --show-toplevel)"
	old_version=$(git show "HEAD:${PROW_CONTROLLER_MANAGER_FILE}" | extract-version)
	version=$(cat "${PROW_CONTROLLER_MANAGER_FILE}" | extract-version)

	if [[ -z "${version}" ]]; then
		echo "Failed to fetch version from ${PROW_CONTROLLER_MANAGER_FILE}"
		exit 1
	fi
	if [[ "${old_version}" == "${version}" ]]; then
		echo "Bump did not change the Prow version: it's still ${version}. Aborting no-op bump." >&2
		return 0
	fi
	git add -u
	title="Bump ${PROW_INSTANCE_NAME} from ${old_version} to ${version}"
	comparison=$(extract-commit "${old_version}")...$(extract-commit "${version}")
	body="Included changes: https://github.com/kubernetes/test-infra/compare/${comparison}"

	if [[ -n "${GH_ORG}" ]]; then
		create-gh-pr
	fi

	echo "autobump.sh completed successfully!" >&2
}

user-from-token() {
	user=$(curl -H "Authorization: token $(cat "${token}")" "https://api.github.com/user" 2>/dev/null | sed -n "s/\s\+\"login\": \"\(.*\)\",/\1/p")
}

ensure-git-config() {
	if [[ $# -eq 2 ]]; then
		echo "git config user.name=$1 user.email=$2..." >&2
		git config --global user.name "$1"
		git config --global user.email "$2"
	fi
	git config user.name &>/dev/null && git config user.email &>/dev/null && return 0
	echo "ERROR: git config user.name, user.email unset. No defaults provided" >&2
	return 1
}

ensure-gpg-keys() {
	echo "gpg keys=$3"
	gpg --import $3
    git config --global commit.gpgsign true
    git config --global user.signingkey $4 #ascii armored public key for gpg keypair
}

check-args() {
	if [[ -z "${PROW_CONTROLLER_MANAGER_FILE}" ]]; then
		echo "ERROR: $PROW_CONTROLLER_MANAGER_FILE must be specified." >&2
		return 1
	fi
	if [[ -z "${GH_ORG}" || -z "${GH_REPO}" ]]; then
		echo "ERROR: GH_ORG and GH_REPO must be specified to create a GitHub PR." >&2
		return 1
	fi
}

create-gh-pr() {
	git commit -s -m "${title}"

	token="${creds}"
	user-from-token

	echo -e "Pushing commit to github.com/${user}/${FORK_GH_REPO}:autobump-${PROW_INSTANCE_NAME}..." >&2
	git push -f "https://${user}:$(cat "${token}")@github.com/${user}/${FORK_GH_REPO}" "HEAD:autobump-${PROW_INSTANCE_NAME}" 2>/dev/null

	echo "Creating PR to merge ${user}:autobump-${PROW_INSTANCE_NAME} into master..." >&2
	/pr-creator \
        --github-endpoint="${GH_PROXY}" \
		--github-token-path="${token}" \
		--org="${GH_ORG}" --repo="${GH_REPO}" --branch=master \
		--title="${title}" --head-branch="autobump-${PROW_INSTANCE_NAME}" \
		--body="${body}" \
		--source="${user}:autobump-${PROW_INSTANCE_NAME}" \
		--confirm
}

# Convert image: gcr.io/k8s-prow/plank:v20181122-abcd to v20181122-abcd
extract-version() {
	local v=$(grep prow-controller-manager:v "$@")
	echo ${v##*prow-controller-manager:}
}
# Convert v20181111-abcd to abcd
extract-commit() {
	local c=$1
	echo ${c##*-}
}

main "$@"
