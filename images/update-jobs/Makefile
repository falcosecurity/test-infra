SHELL := /bin/bash

.DEFAULT_GOAL := build-image

AWS_ECR_REGION ?= eu-west-1
AWS_ECR_ACCOUNT ?= 292999226676
AWS_ECR_NAME := dkr.ecr.$(AWS_ECR_REGION).amazonaws.com
AWS_ECR_REGISTRY := $(AWS_ECR_ACCOUNT).$(AWS_ECR_NAME)

IMG_SLUG := test-infra
IMG_NAME := update-jobs
IMG_TAG ?= latest
IMG_REPOSITORY := $(IMG_SLUG)/$(IMG_NAME)
IMG_FULLNAME := $(AWS_ECR_REGISTRY)/$(IMG_REPOSITORY)

IMAGE := "$(IMG_FULLNAME):$(IMG_TAG)

.DEFAULT_GOAL := build-image

.PHONY: build-push
build-push: build-image push-image

.PHONY: build-image
build-image:
	docker build -t $(IMG_REPOSITORY) .

.PHONY: push-image
push-image:
	docker tag $(IMG_REPOSITORY) $(IMAGE)
	docker push $(IMAGE)

.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) \: 2>/dev/null \
		| awk -v RS= -F: '/^# File/,/^# Finished Make data base/ \
		{if ($$1 !~ "^[#.]") {print $$1}}' | sort | \
		egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
