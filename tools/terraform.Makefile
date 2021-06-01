terraform_version ?= $(shell grep required_version $(PWD)/config/clusters/terraform_versions.tf | cut -d '=' -f2 | tr -d '"' | tr -d ' ')
terraform_workspace := $(PWD)/config/clusters
terraform := docker run --rm -v $(HOME)/.aws/config:/root/.aws/config -v $(HOME)/.aws/credentials:/root/.aws/credentials -v $(terraform_workspace):/workspace -w /workspace -e AWS_PROFILE=$(AWS_PROFILE) hashicorp/terraform:$(terraform_version)

.PHONY: tf-init
tf-init:
	$(terraform) init
	$(terraform) get

.PHONY: tf-lint
tf-lint: tf-init
	$(terraform) validate

.PHONY: tf-plan
tf-plan:
	$(terraform) plan -var-file prow.tfvars

.PHONY: tf-apply
tf-apply: tf-plan
	$(terraform) apply -var-file prow.tfvars -auto-approve
	$(terraform) init -force-copy

.PHONY: tf-clean
tf-clean: tf-init
	$(terraform) destroy -var-file prow.tfvars -auto-approve
