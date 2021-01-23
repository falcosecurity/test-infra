SHELL := /bin/bash


.PHONY: oauth-token hmac-token github-oauth-config cookie plugins update-config

### Prow Components

update-jobs:
	@$(MAKE) -C prow/update-jobs build
	prow/update-jobs/bin/update-jobs --kubeconfig $$HOME/.kube/config --jobs-config-path config/jobs/

oauth-token: 1password-local
	kubectl create secret generic oauth-token --from-literal=oauth="$$(./tools/1password.sh -d config/prow/oauth-token)" --dry-run -o yaml | kubectl replace secret oauth-token -f -

hmac-token: 1password-local
	kubectl create secret generic hmac-token --from-literal=hmac="$$(./tools/1password.sh -d config/prow/hmac-token)" --dry-run -o yaml | kubectl replace secret hmac-token -f -

github-oauth-config:
	kubectl create secret generic github-oauth-config --from-file=secret=./config/prow/github_oauth" --dry-run -o yaml | kubectl replace secret github-oauth-config -f -

cookie:
	kubectl create secret generic cookie --from-file=secret=./config/prow/cookie.txt" --dry-run -o yaml | kubectl replace secret cookie -f -

plugins:
	kubectl create configmap plugins --from-file=plugins.yaml=config/plugins.yaml --dry-run -o yaml | kubectl replace configmap plugins -f -

update-config:
	kubectl create configmap config --from-file=config.yaml=config/config.yaml --dry-run -o yaml | kubectl replace configmap config -f -

prow-s3-credentials: 1password-local
	kubectl create secret generic s3-credentials --from-literal=service-account.json="$$(./tools/1password.sh -d config/prow/service-account.json)" --dry-run -o yaml | kubectl replace secret s3-credentials -f -

prow:
	kubectl apply -f config/prow/

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
	aws eks --region eu-west-1 update-kubeconfig --name falco-prow-test-infra --profile default
