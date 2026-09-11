#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/falco-terraform-aws-test.XXXXXXXX")
test_root=$(cd -- "$test_root" && pwd -P)
trap 'rm -rf -- "$test_root"' EXIT
command -v jq >/dev/null

# An exported shell function shadows Terraform even when the real CLI is installed.
# No provider, backend, credentials or network is used by this test suite.
terraform() {
  local stage=$1 argument plan_file permission
  shift
  printf '%s' "$stage" >>"$MOCK_CASE/trace"
  printf ' %s' "$@" >>"$MOCK_CASE/trace"
  printf '\n' >>"$MOCK_CASE/trace"
  printf 'MOCK_PRIVATE_VALUE from %s stderr\n' "$stage" >&2
  if [[ "$stage" != show ]]; then
    printf 'MOCK_PRIVATE_VALUE from %s stdout\n' "$stage"
  fi
  if [[ "$stage" == "$MOCK_FAIL_STAGE" ]]; then return "$MOCK_FAIL_CODE"; fi
  case "$stage" in
    fmt) [[ "$*" == -check ]] || return 90 ;;
    validate) [[ "$*" == -no-color ]] || return 90 ;;
    init)
      [[ " $* " == *' -lockfile=readonly '* && " $* " == *' -input=false '* &&
         " $* " == *' -lock-timeout=5m '* && " $* " != *' -upgrade '* ]] || return 90
      ;;
    plan)
      [[ " $* " == *' -detailed-exitcode '* && " $* " == *' -input=false '* &&
         " $* " == *' -lock-timeout=5m '* && " $* " != *' -lock=false '* ]] || return 90
      plan_file=''
      for argument in "$@"; do
        case "$argument" in -out=*) plan_file=${argument#-out=} ;; esac
      done
      [[ "$plan_file" == "$RUNNER_TEMP"/falco-terraform-aws.*/plan ]] || return 90
      printf '%s' "$plan_file" >"$MOCK_CASE/plan-path"
      printf 'MOCK_PRIVATE_VALUE saved plan' >"$plan_file"
      permission=$(stat -c '%a' "${plan_file%/plan}" 2>/dev/null) || permission=$(stat -f '%Lp' "${plan_file%/plan}")
      [[ "$permission" == 700 ]] || return 90
      permission=$(stat -c '%a' "$plan_file" 2>/dev/null) || permission=$(stat -f '%Lp' "$plan_file")
      [[ "$permission" == 600 ]] || return 90
      return "$MOCK_PLAN_CODE"
      ;;
    show)
      [[ "$#" == 2 && "$1" == -json && "$2" == "$(<"$MOCK_CASE/plan-path")" ]] || return 90
      if [[ "$MOCK_BAD_JSON" == true ]]; then
        printf 'MOCK_PRIVATE_VALUE invalid JSON'
      else
        printf '%s\n' '{"format_version":"1.1","resource_changes":[{"change":{"actions":["create"],"after":{"secret":"MOCK_PRIVATE_VALUE"}}},{"change":{"actions":["update"]}},{"change":{"actions":["delete","create"]}},{"change":{"actions":["read"]}},{"change":{"actions":["forget"]}},{"change":{"actions":["no-op"]}}],"output_changes":{"secret":{"actions":["create"],"after":"MOCK_PRIVATE_VALUE"}}}'
      fi
      ;;
    apply)
      [[ "$#" == 4 && "$1" == -input=false && "$2" == -no-color && "$3" == -lock-timeout=5m ]] || return 90
      [[ "$4" == "$(<"$MOCK_CASE/plan-path")" && "$(<"$4")" == 'MOCK_PRIVATE_VALUE saved plan' ]] || return 90
      ;;
    *) return 99 ;;
  esac
}
export -f terraform

run_case() {
  local name=$1 expected=$2 plan_code=$3 fail_stage=$4 fail_code=$5 bad_json=$6
  local result=0 output trace
  export MOCK_CASE="$test_root/$name"
  mkdir -p "$MOCK_CASE/runner"
  export RUNNER_TEMP="$MOCK_CASE/runner"
  export MOCK_PLAN_CODE=$plan_code MOCK_FAIL_STAGE=$fail_stage MOCK_FAIL_CODE=$fail_code MOCK_BAD_JSON=$bad_json
  export GITHUB_ACTIONS=true GITHUB_EVENT_NAME=push GITHUB_REF=refs/heads/master GITHUB_REPOSITORY=falcosecurity/test-infra
  export GITHUB_OUTPUT="$MOCK_CASE/github-output" GITHUB_STEP_SUMMARY="$MOCK_CASE/github-summary"
  : >"$MOCK_CASE/trace"
  : >"$GITHUB_OUTPUT"
  : >"$GITHUB_STEP_SUMMARY"
  bash "$script_dir/apply-terraform-aws.sh" >"$MOCK_CASE/output" 2>&1 || result=$?
  if [[ "$expected" == nonzero && "$result" == 0 ]] ||
     [[ "$expected" != nonzero && "$result" != "$expected" ]]; then
    printf 'FAIL %s: expected exit %s, got %s\n' "$name" "$expected" "$result" >&2
    printf '%s\n' "$(<"$MOCK_CASE/trace")" >&2
    exit 1
  fi
  output=$(<"$MOCK_CASE/output")
  trace=$(<"$MOCK_CASE/trace")
  [[ "$output" != *MOCK_PRIVATE_VALUE* && "$output" != *resource_changes* ]]
  [[ ! -s "$GITHUB_OUTPUT" && ! -s "$GITHUB_STEP_SUMMARY" ]]
  # rmdir also detects leftover private plans/logs/artifacts after any exit path.
  rmdir "$RUNNER_TEMP"
  case "$name" in
    changes|apply-failure)
      [[ "$trace" == *$'\napply '* && "$trace" == *$'\nshow -json '* ]]
      [[ "$output" == *'2 to add, 1 to change, 1 to destroy, 1 to read, 1 to forget; 1 output changes.'* ]]
      ;;
    *) [[ "$trace" != *$'\napply '* ]] ;;
  esac
  case "$name" in
    no-changes) [[ "$output" == *'no changes; apply skipped.'* && "$trace" != *$'\nshow '* ]] ;;
    fmt-failure|init-failure|validate-failure) [[ "$trace" != *$'\nplan '* ]] ;;
  esac
  printf 'PASS %s\n' "$name"
}

run_case no-changes 0 0 '' 1 false
run_case changes 0 2 '' 1 false
run_case plan-failure 1 1 '' 1 false
run_case unexpected-plan-exit 17 17 '' 1 false
run_case fmt-failure 11 2 fmt 11 false
run_case init-failure 12 2 init 12 false
run_case validate-failure 13 2 validate 13 false
# jq error codes vary by version; either failure must stop before apply.
run_case show-failure nonzero 2 show 14 false
run_case malformed-json nonzero 2 '' 1 true
run_case apply-failure 15 2 apply 15 false

# An untrusted event is rejected before invoking even the mock Terraform.
export MOCK_CASE="$test_root/untrusted" GITHUB_EVENT_NAME=pull_request
mkdir -p "$MOCK_CASE/runner"
export RUNNER_TEMP="$MOCK_CASE/runner"
: >"$MOCK_CASE/trace"
result=0
bash "$script_dir/apply-terraform-aws.sh" >"$MOCK_CASE/output" 2>&1 || result=$?
[[ "$result" == 1 && ! -s "$MOCK_CASE/trace" ]]
rmdir "$RUNNER_TEMP"
printf 'PASS untrusted-event\n'
