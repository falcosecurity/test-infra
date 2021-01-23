SHELL := /bin/bash

BUILD_CONTEXT ?= ../../prow/update-jobs
DOCKERFILE ?= ./Dockerfile
CACHE_FLAG ?=

IMG_SLUG := test-infra
IMG_NAME := update-jobs
IMG_TAG ?= latest

REGION ?= eu-west-1
ACCOUNT := 292999226676
REGISTRY := $(ACCOUNT).dkr.ecr.$(REGION).amazonaws.com
REPOSITORY := $(IMG_SLUG)/$(IMG_NAME)

IMAGE := $(REGISTRY)/$(REPOSITORY):$(IMG_TAG)

.DEFAULT_GOAL := build-image

.PHONY: build-push
build-push: build-image push-image

.PHONY: build-image
build-image:
	docker build $(CACHE_FLAG) -f $(DOCKERFILE) -t $(REPOSITORY) $(BUILD_CONTEXT)

.PHONY: tag-image
tag-image:
	docker tag $(REPOSITORY) $(IMAGE)

.PHONY: push-image
push-image: tag-image
	docker push $(IMAGE)

.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) \: 2>/dev/null \
		| awk -v RS= -F: '/^# File/,/^# Finished Make data base/ \
		{if ($$1 !~ "^[#.]") {print $$1}}' | sort | \
		egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: local-tag
local-tag: IMAGE := localhost:5000/$(REPOSITORY):$(IMG_TAG)
local-tag:
	docker tag $(REPOSITORY) $(IMAGE)

.PHONY: local-registry
local-registry: IMAGE := localhost:5000/$(REPOSITORY):$(IMG_TAG)
local-registry: build-image local-tag
	docker push $(IMAGE)
