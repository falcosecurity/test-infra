#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set +x
set -euo pipefail
umask 077

# This helper is run from the trusted master checkout, never from a PR checkout.
if [[ "${GITHUB_ACTIONS:-}" != true || "${GITHUB_REF:-}" != refs/heads/master ||
      "${GITHUB_REPOSITORY:-}" != falcosecurity/test-infra ||
      ! "${GITHUB_EVENT_NAME:-}" =~ ^(push|workflow_dispatch|pull_request_target)$ ||
      ( "${GITHUB_EVENT_NAME:-}" == pull_request_target && "${OCI_IDENTITY:-}" != plan ) ]]; then
  echo 'OCI sessions require the upstream master workflow.' >&2
  exit 1
fi
[[ -n "${RUNNER_TEMP:-}" && -d "$RUNNER_TEMP" ]]
trap 'echo "OCI session failed; private diagnostics withheld." >&2' ERR
trap 'exit 130' INT
trap 'exit 143' TERM

validate_directory() {
  [[ "${OCI_SESSION_DIR:-}" == "$RUNNER_TEMP"/oci-session.* &&
     -d "$OCI_SESSION_DIR" && ! -L "$OCI_SESSION_DIR" ]]
  [[ "${OCI_SESSION_DIR#"$RUNNER_TEMP"/}" =~ ^oci-session\.[[:alnum:]]{8}$ ]]
}

remove_session() {
  validate_directory
  rm -rf -- "$OCI_SESSION_DIR"
}

configure_identity() {
  [[ -n "${OCI_OIDC_CLIENT_SECRET:-}" && -n "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]]
  [[ "$OCI_OIDC_DOMAIN_URL" =~ ^https://[a-zA-Z0-9-]+\.identity\.oraclecloud\.com$ ]]
  [[ "$OCI_OIDC_CLIENT_ID" =~ ^[a-zA-Z0-9_-]+$ ]]
  [[ "$OCI_TENANCY_OCID" =~ ^ocid1\.tenancy\.[a-z0-9.]+$ ]]
  [[ "$ACTIONS_ID_TOKEN_REQUEST_URL" == https://* ]]
  mkdir "$OCI_SESSION_DIR/.oci"
  openssl genrsa -out "$OCI_SESSION_DIR/private-key.pem" 2048
  openssl rsa -in "$OCI_SESSION_DIR/private-key.pem" -pubout -outform DER \
    | openssl base64 -A > "$OCI_SESSION_DIR/public-key"
  local fingerprint
  fingerprint=$(openssl base64 -d -A < "$OCI_SESSION_DIR/public-key" | openssl dgst -md5 -c | awk '{print $NF}')
  printf '[CI]\ntenancy=%s\nregion=eu-frankfurt-1\nfingerprint=%s\nkey_file=%s\nsecurity_token_file=%s\n' \
    "$OCI_TENANCY_OCID" "$fingerprint" "$OCI_SESSION_DIR/private-key.pem" \
    "$OCI_SESSION_DIR/session-token" > "$OCI_SESSION_DIR/.oci/config"
  printf 'Authorization: Bearer %s\n' "$ACTIONS_ID_TOKEN_REQUEST_TOKEN" > "$OCI_SESSION_DIR/github-header"
  printf 'Authorization: Basic %s\n' \
    "$(printf '%s:%s' "$OCI_OIDC_CLIENT_ID" "$OCI_OIDC_CLIENT_SECRET" | openssl base64 -A)" \
    > "$OCI_SESSION_DIR/oracle-header"
}

exchange_token() {
  curl -q --fail --silent --show-error --proto '=https' \
    --connect-timeout 10 --max-time 30 --retry 3 --retry-max-time 120 \
    --header "@$OCI_SESSION_DIR/github-header" \
    "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=https%3A%2F%2Fcloud.oracle.com" \
    --output "$OCI_SESSION_DIR/github-response.json"
  jq -ejr '.value | select(type == "string" and length > 0)' \
    "$OCI_SESSION_DIR/github-response.json" > "$OCI_SESSION_DIR/github-token"
  curl -q --fail --silent --show-error --proto '=https' \
    --connect-timeout 10 --max-time 30 --retry 3 --retry-max-time 120 \
    --header "@$OCI_SESSION_DIR/oracle-header" \
    --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' \
    --data-urlencode 'requested_token_type=urn:oci:token-type:oci-upst' \
    --data-urlencode 'subject_token_type=jwt' \
    --data-urlencode "subject_token@$OCI_SESSION_DIR/github-token" \
    --data-urlencode "public_key@$OCI_SESSION_DIR/public-key" \
    "$OCI_OIDC_DOMAIN_URL/oauth2/v1/token" \
    --output "$OCI_SESSION_DIR/oracle-response.json"
  jq -ejr '.token | select(type == "string" and test("^[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$"))' \
    "$OCI_SESSION_DIR/oracle-response.json" > "$OCI_SESSION_DIR/session-token.next"
  # Keep the signing key stable; validate lifetime and replace only the token.
  jq -Rer 'split(".")[1] | gsub("-"; "+") | gsub("_"; "/") | @base64d | fromjson
    | (.exp | type == "number") and .exp > now + 900 and .exp < now + 7200' \
    "$OCI_SESSION_DIR/session-token.next" >/dev/null
  mv "$OCI_SESSION_DIR/session-token.next" "$OCI_SESSION_DIR/session-token"
}

check_renewal() {
  if [[ -e "$OCI_SESSION_DIR/identity-failed" ]] || ! kill -0 "$renewal_pid" 2>/dev/null; then
    echo 'OCI token renewal failed; no further Terraform stage is permitted.' >&2
    exit 1
  fi
}

stop_renewal() {
  local result=$?
  trap - EXIT
  if [[ -n "$renewal_pid" ]]; then
    # Stop only this invocation's child session, including its curl/sleep.
    kill -- "-$renewal_pid" 2>/dev/null || true
    wait "$renewal_pid" 2>/dev/null || true
  fi
  exit "$result"
}

case "${1:-}" in
  start)
    [[ -n "${GITHUB_ENV:-}" ]]
    export OCI_SESSION_DIR
    OCI_SESSION_DIR=$(mktemp -d "$RUNNER_TEMP/oci-session.XXXXXXXX")
    # A failed initialization must not leave credentials behind.
    trap 'result=$?; trap - EXIT; remove_session; exit "$result"' EXIT
    configure_identity > "$OCI_SESSION_DIR/identity.log" 2>&1
    exchange_token >> "$OCI_SESSION_DIR/identity.log" 2>&1
    printf 'OCI_SESSION_DIR=%s\nTF_DATA_DIR=%s/data\nOCI_HOME_OVERRIDE=%s\nTF_HOME_OVERRIDE=%s\n' \
      "$OCI_SESSION_DIR" "$OCI_SESSION_DIR" "$OCI_SESSION_DIR" "$OCI_SESSION_DIR" >> "$GITHUB_ENV"
    trap - EXIT
    echo 'OCI session initialized.'
    ;;
  run)
    validate_directory
    stage=${2:?Missing stage name}
    [[ "$stage" =~ ^[a-z]+$ && ! -e "$OCI_SESSION_DIR/identity-failed" ]]
    shift 2
    [[ $# -gt 0 ]]
    # A fresh token starts each command; no daemon survives between steps.
    exchange_token > "$OCI_SESSION_DIR/identity.log" 2>&1
    unset OCI_OIDC_CLIENT_SECRET ACTIONS_ID_TOKEN_REQUEST_TOKEN
    renewal_pid=
    trap stop_renewal EXIT
    rm -f -- "$OCI_SESSION_DIR/identity-ready"
    export -f exchange_token
    # The quoted program expands variables in the renewal shell, not here.
    # shellcheck disable=SC2016
    setsid bash -euo pipefail -c '
      trap '\''exit 0'\'' INT TERM
      trap '\''result=$?; if (( result != 0 )); then printf "Token renewal failed.\n" > "$OCI_SESSION_DIR/identity-failed"; fi'\'' EXIT
      printf "ready\n" > "$OCI_SESSION_DIR/identity-ready"
      while sleep 300; do exchange_token; done
    ' < /dev/null > "$OCI_SESSION_DIR/renewal.log" 2>&1 &
    renewal_pid=$!
    until [[ -e "$OCI_SESSION_DIR/identity-ready" ]]; do
      check_renewal
      sleep 0.1
    done
    result=0
    if [[ "$stage" == apply ]]; then
      # Stream Terraform UI events, never provider messages, IDs or output values.
      "$@" 2> "$OCI_SESSION_DIR/$stage.err" | tee "$OCI_SESSION_DIR/$stage.log" \
        | jq --unbuffered -r '
            if .type == "apply_start" or .type == "apply_progress" or
               .type == "apply_complete" or .type == "apply_errored" then
              "Terraform \(.type): \(.hook.resource.addr | @json) (\(.hook.action), \(.hook.elapsed_seconds // 0)s)"
            elif .type == "change_summary" then
              "Terraform \(.changes.operation): \(.changes.add) added, \(.changes.change) changed, \(.changes.remove) destroyed."
            elif .type == "diagnostic" then
              "Terraform diagnostic received; provider details withheld."
            else empty end' || result=$?
    else
      "$@" > "$OCI_SESSION_DIR/$stage.log" 2> "$OCI_SESSION_DIR/$stage.err" || result=$?
    fi
    check_renewal
    echo "OCI step $stage completed (exit $result); raw output withheld."
    exit "$result"
    ;;
  cleanup)
    remove_session
    echo 'OCI session and private Terraform files removed.'
    ;;
  *)
    echo 'Usage: oci-session.sh start | run <stage> <command> [args...] | cleanup' >&2
    exit 1
    ;;
esac
