SHELL := /bin/bash

# These are the usual EKS variables.
PROJECT       ?= falco-prow
BUILD_PROJECT ?= falco-prow-builds
ZONE          ?= us-west-2
CLUSTER       ?= falco-prow

update-config:
	kubectl create configmap config --from-file=config.yaml=config/config.yaml --dry-run -o yaml | kubectl replace configmap config -f -

update-plugins:
	kubectl create configmap plugins --from-file=plugins.yaml=config/plugins.yaml --dry-run -o yaml | kubectl replace configmap plugins -f -

update-jobs:
	go run prow/update-jobs/main.go --kubeconfig $$HOME/.kube/config --jobs-config-path config/jobs/



update-cat-api-key: get-cluster-credentials
	kubectl create configmap cat-api-key --from-file=api-key=plugins/cat/api-key --dry-run -o yaml | kubectl replace configmap cat-api-key -f -

.PHONY: update-config update-plugins update-cat-api-key




config/prow/oauth-token.yaml: oauth
	kubectl create secret generic --dry-run -o yaml oauth-token --from-file=$< >> $@

config/prow/hmac-token.yaml: hmac
	kubectl create secret generic --dry-run -o yaml hmac-token --from-file=$< >> $@

config/prow/unsplash-token.yaml: unsplash_secret
	kubectl create secret generic --dry-run -o yaml unsplash-token --from-file=$< >> $@

prow: config/prow/oauth-token.yaml config/prow/hmac-token.yaml config/prow/unsplash-token.yaml config/prow/*.yaml
	kubectl apply -f config/prow/

plugins: config/plugins.yaml
	kubectl create configmap plugins --from-file=plugins.yaml=config/plugins.yaml --dry-run -o yaml | kubectl replace configmap plugins -f -

update-config:
	kubectl create configmap config --from-file=config.yaml=config/config.yaml --dry-run -o yaml | kubectl replace configmap config -f -

clean:
	rm -f config/prow/oauth-token.yaml
	rm -f config/prow/hmac-token.yaml
	rm -f config/prow/unsplash-token.yaml



#### Terraform #####

tf-init:
	terraform init config/clusters
	terraform get

tf-lint: tf-init
	terraform validate config/clusters
	terraform plan -var-file config/clusters/prow.tfvars config/clusters

tf-apply: tf-lint
	terraform apply -var-file config/clusters/prow.tfvars -auto-approve config/clusters
	terraform init -force-copy config/clusters

tf-clean: tf-init
	terraform destroy -var-file config/clusters/prow.tfvars -auto-approve config/clusters

kubeconfig:
	aws eks --region us-west-2 update-kubeconfig --name falco-prow-test-infra --profile falco
