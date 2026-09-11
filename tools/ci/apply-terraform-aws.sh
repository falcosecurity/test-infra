#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# This entrypoint belongs to the trusted post-merge workflow, not presubmits.
if [[ "${GITHUB_ACTIONS:-}" != true || "${GITHUB_EVENT_NAME:-}" != push ||
      "${GITHUB_REF:-}" != refs/heads/master ||
      "${GITHUB_REPOSITORY:-}" != falcosecurity/test-infra ]]; then
  echo 'AWS Terraform apply requires the upstream master push workflow.' >&2
  exit 1
fi
if [[ -z "${RUNNER_TEMP:-}" || ! -d "$RUNNER_TEMP" ]]; then
  echo 'AWS Terraform apply requires an existing RUNNER_TEMP directory.' >&2
  exit 1
fi
command -v terraform >/dev/null
command -v jq >/dev/null

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd "$repo_root/config/clusters/aws"
runner_temp_root=$(cd -- "$RUNNER_TEMP" && pwd -P)
umask 077
run_dir=$(mktemp -d "$runner_temp_root/falco-terraform-aws.XXXXXXXX")

cleanup() {
  local result=$?
  trap - EXIT
  # Only remove the private directory created by this invocation.
  if [[ "$run_dir" == "$runner_temp_root"/falco-terraform-aws.* &&
        -d "$run_dir" && ! -L "$run_dir" ]]; then
    if ! rm -f -- "$run_dir/plan" "$run_dir/fmt.log" "$run_dir/init.log" \
      "$run_dir/validate.log" "$run_dir/plan.log" "$run_dir/show.log" \
      "$run_dir/summary.log" "$run_dir/apply.log" || ! rmdir -- "$run_dir"; then
      echo 'AWS Terraform temporary-file cleanup failed.' >&2
      if (( result == 0 )); then result=1; fi
    fi
  else
    echo 'AWS Terraform temporary-directory validation failed.' >&2
    if (( result == 0 )); then result=1; fi
  fi
  exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

run_private() {
  local stage=$1 result
  shift
  if "$@" >"$run_dir/$stage.log" 2>&1; then
    echo "AWS Terraform $stage succeeded."
  else
    result=$?
    echo "AWS Terraform $stage failed (exit $result); raw output withheld because it may contain sensitive values." >&2
    exit "$result"
  fi
}

run_private fmt terraform fmt -check
run_private init terraform init -input=false -lockfile=readonly -lock-timeout=5m -no-color
run_private validate terraform validate -no-color

plan_result=0
terraform plan -input=false -no-color -lock-timeout=5m -detailed-exitcode \
  -out="$run_dir/plan" >"$run_dir/plan.log" 2>&1 || plan_result=$?
case "$plan_result" in
  0)
    echo 'AWS Terraform: no changes; apply skipped.'
    exit 0
    ;;
  2) ;;
  *)
    echo "AWS Terraform plan failed (exit $plan_result); raw output withheld because it may contain sensitive values." >&2
    exit "$plan_result"
    ;;
esac

# Only counts leave this pipeline; resource names, output values and raw JSON do not.
if summary=$(terraform show -json "$run_dir/plan" 2>"$run_dir/show.log" | jq -er '
  if type != "object" or (.format_version | type) != "string" then
    error("Invalid Terraform plan JSON")
  else . end
  | def count_action($action):
      [.resource_changes[]? | select(.change.actions | index($action))] | length;
    "AWS Terraform plan: \(count_action("create")) to add, \(count_action("update")) to change, \(count_action("delete")) to destroy, \(count_action("read")) to read, \(count_action("forget")) to forget; \([(.output_changes // {})[] | select(.actions != ["no-op"])] | length) output changes."
' 2>"$run_dir/summary.log"); then
  echo "$summary"
else
  result=$?
  echo "AWS Terraform plan summary failed (exit $result); apply not started." >&2
  exit "$result"
fi

# Passing the saved plan is non-interactive and does not generate a second plan.
run_private apply terraform apply -input=false -no-color -lock-timeout=5m "$run_dir/plan"
