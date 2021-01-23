#!/usr/bin/env bash
#
# Copyright (C) 2020 The Falco Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Requires go, docker, and kubectl.

set -o errexit
set -o nounset
set -o pipefail
set -x

DEBUG="${DEBUG:-"false"}"

# We use a .local file because the update-jobs configmap will merge all yaml together into one configmap
CONFIG_PATH="${CONFIG_PATH:-"$(pwd)/config/config.yaml"}"
JOB_CONFIG_PATH="${JOB_CONFIG_PATH:-"$(pwd)/config/jobs/driverkit/driverkit-test.local"}"
IMAGE_PATH="${IMAGE_PATH:-"$(pwd)/images/golang"}"
CLUSTER_NAME=update-jobs-test

export CONFIG_PATH
export JOB_CONFIG_PATH
export IMAGE_PATH
# Point kubectl at the ${CLUSTER_NAME} cluster.
export KUBECONFIG="${HOME}/.kube/kind-config-${CLUSTER_NAME}"

function ask_confirm() {
  read -p "Confirm? [y/n] " -n 1 -r

  if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "Canceled."
    exit 0
  fi
}

function deploy_pod_and_watch() {
  echo
  echo "Applying pod to the ${CLUSTER_NAME} cluster. Configure kubectl for the ${CLUSTER_NAME} cluster with:"
  echo ">  export KUBECONFIG='${KUBECONFIG}'"
  echo
  pod=$(kubectl apply -f "${PWD}/pod.yaml" | cut -d ' ' -f 1)
  kubectl get "${pod}" -w
}

function connect_kind_network_to_local_registry_network() {
  local kind_network='bridge'
  local reg_name='kind-registry'
  docker network connect "${kind_network}" "${reg_name}" || true
}

function build_and_push_job_image_to_local_registry() {
  make -C "${image_path}" local-registry
}

function generate_prow_job() {
  docker run --rm -i \
    -v "${PWD}:${PWD}" \
    -v "${config}:${config}" \
    ${job_config_mnt} \
    -w "${PWD}" \
    gcr.io/k8s-prow/mkpj \
    "--config-path=${config}" \
    "--job=${job}" ${job_config_flag} \
    > "${PWD}/pj.yaml"
}

function generate_prow_pod() {
  docker run --rm -i \
    -v "${PWD}:${PWD}" \
    -w "${PWD}" \
    gcr.io/k8s-prow/mkpod \
    --build-id=snowflake \
    "--prow-job=${PWD}/pj.yaml" \
    --local "--out-dir=${out_dir}/${job}" \
    > "${PWD}/pod.yaml"
}

# Ensures installation of prow tools, kind, and a kind cluster named "${CLUSTER_NAME}".
function ensureInstall() {

  # Install kind and set up cluster if not already done.
  if ! command -v kind >/dev/null 2>&1; then
    echo "Installing kind..."
    GO111MODULE="on" go get sigs.k8s.io/kind@v0.7.0
  fi

  local found="false"

  for clust in $(kind get clusters); do
    if [[ "${clust}" == "${CLUSTER_NAME}" ]]; then
      found="true"
      break
    fi
  done

  if [[ "${found}" == "false" ]]; then
    # Need to create the "${CLUSTER_NAME}" kind cluster.
    if [[ -n "${kind_config}" ]]; then
      echo "$kind_config"
      kind create cluster --name="${CLUSTER_NAME}" --config="./temp-${CLUSTER_NAME}-kind-config.yaml" --wait=5m --loglevel=debug
    else
      # Create a temporary kind config file.
      local temp_config="${PWD}/temp-${CLUSTER_NAME}-kind-config.yaml"
      if [ "${kind_network}" = "bridge" ]; then
          reg_host="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' kind-registry)"
      fi
      echo "Registry Host: ${reg_host}"
      cat <<EOF > "${temp_config}"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
    endpoint = ["http://${reg_host}:5000"]
nodes:
  - extraMounts:
      - containerPath: ${out_dir}
        hostPath: ${PWD}
      # host <-> node mount for hostPath volumes in Pods. (All hostPaths should be under ${node_dir} to reach the host.)
      - containerPath: ${node_dir}
        hostPath: ${PWD}
EOF
      kind create cluster --name=${CLUSTER_NAME} "--config=${temp_config}" --wait=5m
      rm "${temp_config}"
    fi
  else
    if docker ps -a | grep "${CLUSTER_NAME}-control-plane" > /dev/null 1>&2; then
      is_kind_controlplane_running="$(docker inspect -f '{{.State.Running}}' "${CLUSTER_NAME}-control-plane" 2>/dev/null || true)"
      if [ "${is_kind_controlplane_running}" != "true" ]; then
        docker start "${CLUSTER_NAME}-control-plane"
        echo "Done."
      fi
    fi
  fi
}

function local_registry() {
  # create registry container unless it already exists
  reg_name='kind-registry'
  reg_port='5000'
  kind_network='bridge'
  reg_host="${reg_name}"
  running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"

  if [ "${running}" != 'true' ]; then
    docker run \
      -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
      registry:2
  fi
}

function parseArgs() {
  # Use node mounts under /mnt/disks/ so pods behave well on COS nodes too. https://cloud.google.com/container-optimized-os/docs/concepts/disks-and-filesystem
  job="${1:-}"
  config="${CONFIG_PATH:-}"
  job_config_path="${JOB_CONFIG_PATH:-}"
  image_path="${IMAGE_PATH:-}"
  out_dir="${OUT_DIR:-/mnt/disks/prowjob-out}"
  kind_config="${KIND_CONFIG:-}"
  node_dir="${NODE_DIR:-/mnt/disks/kind-node}" # Any pod hostPath mounts should be under this dir to reach the true host via the kind node.

  local new_only=" (Only used when creating a new kind cluster.)"

  if [ "${DEBUG}" = "true" ]; then
    echo "job=${job}"
    echo "CONFIG_PATH=${config}"
    echo "JOB_CONFIG_PATH=${job_config_path}"
    echo "IMAGE_PATH=${image_path}"
    echo "OUT_DIR=${out_dir} ${new_only}"
    echo "KIND_CONFIG=${kind_config} ${new_only}"
    echo "NODE_DIR=${node_dir} ${new_only}"
    ask_confirm
  fi

  if [[ -z "${job}" ]]; then
    echo "Must specify a job name as the first argument."
    exit 2
  fi

  if [[ -z "${config}" ]]; then
    echo "Must specify config.yaml location via CONFIG_PATH env var."
    exit 2
  fi

  job_config_flag=""
  job_config_mnt=""

  if [[ -n "${job_config_path}" ]]; then
    job_config_flag="--job-config-path=${job_config_path}"
    job_config_mnt="-v ${job_config_path}:${job_config_path}"
  fi
}

function main() {

  # Prep and check args.
  parseArgs "$@"

  local_registry

  ensureInstall

  build_and_push_job_image_to_local_registry

  # Generate PJ and Pod.
  generate_prow_job
  generate_prow_pod

  # Add any k8s resources that the pod depends on to the kind cluster here. (secrets, configmaps, etc.)
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:5000"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
  cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: test-pods
EOF
  cat ${PWD}/config/prow/update-jobs.yaml | kubectl apply -f -

  # Connect kind to local registry if not connected
  connect_kind_network_to_local_registry_network

  # Deploy pod and watch.
  deploy_pod_and_watch
}

main "$@"
