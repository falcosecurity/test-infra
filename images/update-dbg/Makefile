SHELL := /bin/bash

IMG_SLUG := test-infra
IMG_NAME := update-dbg
IMG_TAG ?= latest

DOCKER_PUSH_REPOSITORY := ghcr.io/falcosecurity

IMAGE := "$(DOCKER_PUSH_REPOSITORY)/$(IMG_SLUG)/$(IMG_NAME):$(IMG_TAG)"

build-push: build-image push-image

build-image:
	docker build --no-cache -t "$(IMG_SLUG)/$(IMG_NAME)" .

push-image:
	docker tag "$(IMG_SLUG)/$(IMG_NAME)" $(IMAGE)
	docker push $(IMAGE)

local-registry:
	docker tag "$(IMG_SLUG)/$(IMG_NAME)" localhost:5000/$(IMG_NAME)
	docker push localhost:5000/$(IMG_NAME)
