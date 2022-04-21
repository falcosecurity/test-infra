#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Prow configuration
PROW_ENV=local
PROW_CONFIG_PATH="./config/${PROW_ENV}"

# 1Password secrets path
OP_PATH_PREFIX="config/${PROW_ENV}/prow"
OP_BIN="./tools/1password.sh"

CERTMANAGER_VERSION="v1.8.0"

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

readonly PROW_COMPONENTS="sinker crier hook horologium prow-controller-manager deck tide"

function pretty_echo() {
	echo
	echo "	> ${@}"
	echo
}

function configInfra() {
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERTMANAGER_VERSION}/cert-manager.yaml
	helm upgrade --install --namespace minio --create-namespace minio minio/minio -f config/${PROW_ENV}/minio/values.yaml
}

function configProw() {
	kubectl create namespace test-pods || true
	kubectl create configmap plugins --from-file=plugins.yaml=${PROW_CONFIG_PATH}/plugins.yaml || true
	kubectl create configmap config --from-file "${PROW_CONFIG_PATH}/config.yaml" || true
	kubectl create configmap config --from-file "${PROW_CONFIG_PATH}/config.yaml" -n test-pods || true
	kubectl create configmap job-config
	make -C prow/update-jobs build && ./prow/update-jobs/bin/update-jobs --kubeconfig $KUBECONFIG --jobs-config-path ./config/local/jobs
	kubectl create configmap branding --from-file "config/branding" || true
	kubectl create secret generic s3-credentials --from-file="config/${PROW_ENV}/minio/service-account.json" || true

	#Github related items
	kubectl create secret generic hmac-token --from-literal=hmac="$(${OP_BIN} -d ${OP_PATH_PREFIX}/hmac-token)" || true
	kubectl create secret generic oauth-token --from-literal=oauth="$(${OP_BIN} -d ${OP_PATH_PREFIX}/oauth-token)" || true
	kubectl create secret generic oauth-token --from-literal=oauth="$(${OP_BIN} -d ${OP_PATH_PREFIX}/oauth-token)" -n test-pods || true

	# PR Status
	kubectl create secret generic github-oauth-config --from-literal=secret="$(${OP_BIN} -d ${OP_PATH_PREFIX}/prstatus-github-oauth-app.yaml)" || true
	kubectl create secret generic cookie --from-literal=secret="$(${OP_BIN} -d prow-prstatus-cookie-encryption-key.txt)" || true
}

function launchConfig(){
	configInfra
	configProw
}

function deployProw(){
	kubectl apply -f ${PROW_CONFIG_PATH}/prow
}

function waitProwReadiness(){
	sleep 5
	pretty_echo "Wait until nginx is ready"
	for _ in $(seq 1 5); do
	  if kubectl wait --namespace ingress-nginx \
	    --for=condition=ready pod \
	    --selector=app.kubernetes.io/component=controller \
	    --timeout=5m; then
	    break
	  else
	    sleep 5
	  fi
	done
	pretty_echo "Nginx is ready"

	sleep 5
	pretty_echo "Waiting for prow components"
	for app in ${PROW_COMPONENTS}; do
	  kubectl wait pod \
	    --for=condition=ready \
	    --selector=app=${app} \
	    --timeout=5m
	done
	pretty_echo "Prow is ready"
}

function cleanup() {
	kind delete cluster --name prow
	returnCode="$?"
	exit "${returnCode}"
}

function main() {
	pretty_echo "Launching Configmaps, and prereq software" 
	launchConfig
	pretty_echo "Launching Prow microservices" 
	deployProw
	waitProwReadiness
	echo "All done!"
	pretty_echo "Please make prow.falco.local resolvable to 127.0.0.1 IP address"
}

trap cleanup SIGINT
main "$@"
