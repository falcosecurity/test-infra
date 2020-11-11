#!/bin/bash

set -eo pipefail

SCRIPT_NAME="$(basename $0)"

SIGNIN="${OP_SIGNIN_ADDRESS}"
EMAIL="${OP_EMAIL_ADDRESS}"
SECRET_KEY="${OP_SECRET_KEY}"
MASTER_KEY="${OP_MASTER_KEY}"
ITEM_TYPE=""
BINPATH="/usr/local/bin"
VAULT_NAME=""
DOCUMENT_NAME=""

# BINPATH="$(mktemp -d)/bin"
# OP="${BINPATH}/op"
VERBOSE="false"

function show_usage {
  echo "Usage: ${SCRIPT_NAME} -d DOCUMENT_NAME [-v VAULT_NAME]"
  echo
  echo "Required environment variables:"
  echo " OP_SIGNIN_ADDRESS"
  echo " OP_EMAIL_ADDRESS"
  echo " OP_SECRET_KEY"
  echo " OP_MASTER_KEY"
}

function op_ensure_installed {
  local tmpdir=""
  local gpg=$(which gpg)
  local os="notset"

  if ! type op &> /dev/null; then
    case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
        os="linux"
        ;;
    darwin*)
        os="darwin"
        ;;
    *)
        export OS_NAME=$os
        ;;
    esac

    tmpdir=$(mktemp -d)
    curl -s \
      "https://cache.agilebits.com/dist/1P/op/pkg/v1.7.0/op_${os}_amd64_v1.7.0.zip" \
      -o $tmpdir/op.zip
    unzip $tmpdir/op.zip -d $tmpdir/ \
      > /dev/null
    # $gpg --recv-keys \
    #   --keyserver pool.sks-keyservers.net \
    #   3FEF9748469ADBE15DA7CA80AC2D62742012EA22 \
    #   > /dev/null 2>&1
    # $gpg --verify \
    #   $tmpdir/op.sig \
    #   $tmpdir/op \
    mv $tmpdir/op "${BINPATH}/"
    rm -rf $tmpdir
  fi
}

function op_signin {
  local signin=$1
  local email=$2
  local secret_key=$3
  local master_key=$4
  eval $(echo -n "${master_key}" | op signin "${signin}" "${email}" "${secret_key}")
}

function op_list_item_titles {
  op list items | jq '.[].overview.title'
}

function op_ensure_uninstalled {
  rm "${BINPATH}/op"
}

function op_get_document {
  local document_name=$1
  local vault_name=$2

  if [ -z "${VAULT_NAME}" ]; then
    op get document $document_name
  else
    op get document $document_name \
      --vault $vault_name
  fi
}

while getopts ":hv:d:" opt; do
  case ${opt} in
    h ) show_usage;
      exit 0
      ;;
    v ) VAULT_NAME="${OPTARG}";
      ;;
    d ) ITEM_TYPE="document";
      DOCUMENT_NAME="${OPTARG}";
      ;;
    : ) echo "Option -${OPTARG} requires an argument" >&2;
      show_usage;
      exit 1
      ;;
    \? ) echo "Invalid option: -${OPTARG}" >&2;
      show_usage;
      exit 1
      ;;
  esac
done

[ -z "${DOCUMENT_NAME}" ] && \
  { show_usage; exit 1 ; }

op_ensure_installed
op_signin "${SIGNIN}" "${EMAIL}" "${SECRET_KEY}" "${MASTER_KEY}"
[ "${ITEM_TYPE}" == "document" ] && \
  op_get_document "${DOCUMENT_NAME}" "${VAULT_NAME}"
# op_ensure_uninstalled $OP
