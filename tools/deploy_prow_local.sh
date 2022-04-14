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
	# TODO: stick with https://github.com/kubernetes/test-infra/blob/master/prow/getting_started_deploy.md
}

function configProw() {
	kubectl create namespace test-pods
	kubectl create configmap -n default plugins --from-file=plugins.yaml=${PROW_CONFIG_PATH}/plugins.yaml
	kubectl create configmap -n default config --from-file "${PROW_CONFIG_PATH}/config.yaml"
	kubectl create configmap -n test-pods config --from-file "${PROW_CONFIG_PATH}/config.yaml"
	kubectl create configmap -n default job-config
	make -C prow/update-jobs build && ./prow/update-jobs/bin/update-jobs --kubeconfig $KUBECONFIG --jobs-config-path ./config/local/jobs
	kubectl create configmap -n default branding --from-file "config/branding"
	kubectl create secret generic -n default s3-credentials --from-file="config/${PROW_ENV}/minio/service-account.json"
	kubectl create secret generic -n test-pods s3-credentials --from-file="config/${PROW_ENV}/minio/service-account.json"

	#Github related items
	kubectl create secret generic -n default hmac-token --from-literal=hmac="$(${OP_BIN} -d ${OP_PATH_PREFIX}/hmac-token)"
	kubectl create secret generic -n default oauth-token --from-literal=oauth="$(${OP_BIN} -d ${OP_PATH_PREFIX}/oauth-token)"
	kubectl create secret generic -n test-pods oauth-token --from-literal=oauth="$(${OP_BIN} -d ${OP_PATH_PREFIX}/oauth-token)"

	# PR Status
	kubectl create secret generic -n default github-oauth-config --from-literal=secret="$(${OP_BIN} -d ${OP_PATH_PREFIX}/prstatus-github-oauth-app.yaml)"
	kubectl create secret generic -n default cookie --from-literal=secret="$(${OP_BIN} -d prow-prstatus-cookie-encryption-key.txt)"
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
	  kubectl wait -n default pod \
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
