SHELL := /bin/bash

IMG_SLUG := test-infra
IMG_NAME := update-maintainers
IMG_TAG ?= latest

ACCOUNT := 292999226676
DOCKER_PUSH_REPOSITORY = dkr.ecr.eu-west-1.amazonaws.com

IMAGE := "$(ACCOUNT).$(DOCKER_PUSH_REPOSITORY)/$(IMG_SLUG)/$(IMG_NAME)"

build-push: build-image push-image

build-image:
	docker build -t "$(IMG_SLUG)/$(IMG_NAME)" .

push-image:
	docker tag "$(IMG_SLUG)/$(IMG_NAME)" "$(IMAGE):$(TAG)"
	docker push "$(IMAGE):$(TAG)"

local-registry:
	docker tag "$(IMAGE):$(TAG)" localhost:5000/$(IMG_NAME)
	docker push localhost:5000/$(IMG_NAME)