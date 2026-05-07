#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2026 The Falco Authors.
#
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

GH_PROXY="${GH_PROXY:-"http://ghproxy"}"
GH_ORG="${GH_ORG:-"falcosecurity"}"
GH_REPO="${GH_REPO:-"charts"}"
GH_REPO_BRANCH="${GH_REPO_BRANCH:-"master"}"
BOT_NAME="${BOT_NAME:-"poiana"}"
BOT_MAIL="${BOT_MAIL:-"51138685+poiana@users.noreply.github.com"}"
BOT_GPG_KEY_PATH="${BOT_GPG_KEY_PATH:-"/root/gpg-signing-key/poiana.asc"}"
BOT_GPG_PUBLIC_KEY="${BOT_GPG_PUBLIC_KEY:-"EC9875C7B990D55F3B44D6E45F284448FF941C8F"}"
SOURCE_REPO_PATH="${SOURCE_REPO_PATH:-"/home/prow/go/src/github.com/falcosecurity/falco-operator"}"
SOURCE_CHART_PATH="${SOURCE_CHART_PATH:-"chart/falco-operator"}"
TARGET_CHART_PATH="${TARGET_CHART_PATH:-"charts/falco-operator"}"
PR_BRANCH="${PR_BRANCH:-"update/falco-operator-chart"}"
PR_TITLE="${PR_TITLE:-"update(falco-operator): sync Helm chart"}"

export GIT_COMMITTER_NAME="${BOT_NAME}"
export GIT_COMMITTER_EMAIL="${BOT_MAIL}"
export GIT_AUTHOR_NAME="${BOT_NAME}"
export GIT_AUTHOR_EMAIL="${BOT_MAIL}"

check_program() {
    if hash "$1" 2>/dev/null; then
        type -P "$1" >&/dev/null
    else
        echo "> aborting because $1 is required..." >&2
        return 1
    fi
}

ensure_git_config() {
    echo "> configuring git user (name=$1, email=$2)..." >&2
    git config --global user.name "$1"
    git config --global user.email "$2"

    git config user.name &>/dev/null && git config user.email &>/dev/null && return 0
    echo "ERROR: git config user.name, user.email unset. No defaults provided" >&2
    return 1
}

ensure_gpg_key() {
    echo "> configuring git with gpg key=$1..." >&2
    gpg --import "$1"
    git config --global commit.gpgsign true
    git config --global user.signingkey "$2"

    git config --global commit.gpgsign &>/dev/null && git config --global user.signingkey &>/dev/null && return 0
    echo "ERROR: git gpg key location, public key ID unset. No defaults provided" >&2
    return 1
}

require_file() {
    if [[ ! -f "$1" ]]; then
        echo "ERROR: required file not found: $1" >&2
        return 1
    fi
}

require_dir() {
    if [[ ! -d "$1" ]]; then
        echo "ERROR: required directory not found: $1" >&2
        return 1
    fi
}

source_chart_dir() {
    if [[ "${SOURCE_CHART_PATH}" = /* ]]; then
        printf "%s" "${SOURCE_CHART_PATH}"
    else
        printf "%s/%s" "${SOURCE_REPO_PATH}" "${SOURCE_CHART_PATH}"
    fi
}

chart_version() {
    local chart_dir="$1"
    local version

    version="$(helm show chart "${chart_dir}" | awk '$1 == "version:" { print $2; exit }')"
    if [[ -z "${version}" ]]; then
        echo "ERROR: unable to read Chart.yaml version from ${chart_dir}" >&2
        return 1
    fi

    printf "%s" "${version}"
}

validate_chart_layout() {
    local chart_dir="$1"

    require_file "${chart_dir}/.helmignore"
    require_file "${chart_dir}/CHANGELOG.md"
    require_file "${chart_dir}/Chart.yaml"
    require_file "${chart_dir}/README.gotmpl"
    require_file "${chart_dir}/README.md"
    require_file "${chart_dir}/values.yaml"
    require_dir "${chart_dir}/crds"
    require_dir "${chart_dir}/templates"
}

validate_target_chart_path() {
    local chart_dir="$1"

    if [[ -z "${chart_dir}" || "${chart_dir}" = /* ]]; then
        echo "ERROR: refusing invalid target chart path: ${chart_dir}" >&2
        return 1
    fi

    if [[ "${chart_dir}" == "charts" || "${chart_dir}" == "charts/" ]]; then
        echo "ERROR: refusing to sync the whole charts directory" >&2
        return 1
    fi

    case "${chart_dir}" in
        charts/*) ;;
        *)
            echo "ERROR: refusing to sync outside charts/: ${chart_dir}" >&2
            return 1
            ;;
    esac

    case "/${chart_dir}/" in
        *"//"*|*"/../"*|*"/./"*)
            echo "ERROR: refusing target chart path with relative segments: ${chart_dir}" >&2
            return 1
            ;;
    esac
}

validate_chart_rendering() {
    local chart_dir="$1"

    echo "> linting ${chart_dir}..." >&2
    helm lint --strict "${chart_dir}"

    echo "> rendering ${chart_dir}..." >&2
    helm template falco-operator "${chart_dir}" \
        --namespace falco-operator \
        --include-crds \
        >/tmp/falco-operator-chart-render.yaml

    echo "> packaging ${chart_dir}..." >&2
    helm package "${chart_dir}" -d /tmp >/tmp/falco-operator-chart-package.log
}

sync_chart() {
    local source_dir="$1"
    local target_dir="$2"
    local target_exists=false
    local previous_version=""
    local current_version

    validate_chart_layout "${source_dir}"
    validate_target_chart_path "${target_dir}"
    current_version="$(chart_version "${source_dir}")"

    if [[ -f "${target_dir}/Chart.yaml" ]]; then
        target_exists=true
        previous_version="$(chart_version "${target_dir}")"
    fi

    echo "> syncing ${source_dir} to ${target_dir}..." >&2
    mkdir -p "${target_dir}"
    rsync -a --delete --exclude ".git" --exclude "OWNERS" "${source_dir}/" "${target_dir}/"

    validate_chart_layout "${target_dir}"
    validate_chart_rendering "${target_dir}"

    if [[ "$(git status --porcelain=v1 -- "${target_dir}" | wc -l | tr -d ' ')" -gt 0 ]]; then
        if [[ "${target_exists}" == "true" && "${previous_version}" == "${current_version}" ]]; then
            echo "ERROR: chart changes detected but Chart.yaml version is still ${current_version}." >&2
            echo "ERROR: bump the chart version in falcosecurity/falco-operator before syncing to falcosecurity/charts." >&2
            return 1
        fi
    fi
}

get_user_from_token() {
    curl --silent -H "Authorization: token $(cat "$1")" "https://api.github.com/user" | grep -Po '"login": "\K.*?(?=")'
}

create_pr() {
    local token_path="$1"
    local nchanges
    local user
    local body

    nchanges="$(git status --porcelain=v1 -- "${TARGET_CHART_PATH}" | wc -l | tr -d ' ')"
    if [[ "${nchanges}" -eq 0 ]]; then
        echo "> moving on since there are no changes..." >&2
        return 0
    fi

    echo "> creating commit..." >&2
    git add "${TARGET_CHART_PATH}"
    git commit -s -m "${PR_TITLE}"

    user="$(get_user_from_token "${token_path}")"
    echo "> pushing commit as ${user} on branch ${PR_BRANCH}..." >&2
    git push -f \
        "https://${user}:$(cat "${token_path}")@github.com/${GH_ORG}/${GH_REPO}" \
        "HEAD:${PR_BRANCH}" 2>/dev/null

    echo "> creating pull-request to merge ${user}:${PR_BRANCH} into ${GH_REPO_BRANCH}..." >&2
    body="$(cat <<'EOF'
**What type of PR is this?**

/kind chart-release

**Any specific area of the project related to this PR?**

/area falco-operator-chart

**What this PR does / why we need it**:

Syncs the Falco Operator Helm chart from `falcosecurity/falco-operator`.

Source chart: https://github.com/falcosecurity/falco-operator/tree/main/chart/falco-operator

**Which issue(s) this PR fixes**:

None.

**Special notes for your reviewer**:

Generated by the update-falco-operator-chart ProwJob. Do not edit this PR directly; change the source chart in `falcosecurity/falco-operator` instead.

**Checklist**
- [x] Chart Version bumped
- [x] Variables are documented in the README.md
- [x] CHANGELOG.md updated
EOF
)"

    pr-creator \
        --github-endpoint="${GH_PROXY}" \
        --github-token-path="${token_path}" \
        --org="${GH_ORG}" --repo="${GH_REPO}" --branch="${GH_REPO_BRANCH}" \
        --title="${PR_TITLE}" --match-title="${PR_TITLE}" \
        --body="${body}" \
        --local --source="${PR_BRANCH}" \
        --allow-mods --confirm
}

main() {
    local token_path="$1"
    local source_dir

    check_program "awk"
    check_program "curl"
    check_program "git"
    check_program "gpg"
    check_program "helm"
    check_program "pr-creator"
    check_program "rsync"

    require_file "${token_path}"
    ensure_git_config "${BOT_NAME}" "${BOT_MAIL}"
    ensure_gpg_key "${BOT_GPG_KEY_PATH}" "${BOT_GPG_PUBLIC_KEY}"

    source_dir="$(source_chart_dir)"
    sync_chart "${source_dir}" "${TARGET_CHART_PATH}"
    create_pr "${token_path}"
}

if [[ $# -lt 1 ]]; then
    echo "Usage: $(basename "$0") <path to github token>" >&2
    exit 1
fi

main "$@"
