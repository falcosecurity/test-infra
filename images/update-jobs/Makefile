this_path := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

BUILD_CONTEXT ?= ../../prow/update-jobs
DOCKERFILE ?= ./Dockerfile
CACHE_FLAG ?=

IMG_SLUG := test-infra
IMG_NAME := update-jobs
IMG_TAG ?= latest

include $(this_path)/../common.Makefile

.DEFAULT_GOAL := build-image

.PHONY: local-tag
local-tag: IMAGE := localhost:5000/$(IMG_SLUG)/$(IMG_NAME):$(IMG_TAG)
local-tag:
	docker tag $(IMG_SLUG)/$(IMG_NAME) $(IMAGE)

.PHONY: local-registry
local-registry: IMAGE := localhost:5000/$(IMG_SLUG)/$(IMG_NAME):$(IMG_TAG)
local-registry: build-image local-tag
	docker push $(IMAGE)

.PHONY: test
test:
	@DEBUG=true \
		CONFIG_PATH="$(PWD)/../../config/config.yaml" \
		JOB_CONFIG_PATH="$(PWD)/../../config/jobs/update-jobs/update-jobs.local" \
		IMAGE_PATH="$(PWD)/../../images/update-jobs" \
		./test.sh update-jobs-pr
