SHELL := /usr/bin/env bash

cosign := $(shell command -v cosign 2>/dev/null)
cosign_version ?= 1.9.0
cosign_key ?= k8s://cosign/openinfra-oci-sign

IMG_SLUG := test-infra
IMG_NAME := build-libs
IMG_TAG ?= latest

ACCOUNT := 292999226676
DOCKER_PUSH_REPOSITORY = dkr.ecr.eu-west-1.amazonaws.com

IMAGE := "$(ACCOUNT).$(DOCKER_PUSH_REPOSITORY)/$(IMG_SLUG)/$(IMG_NAME):$(IMG_TAG)"

ARCHS := "arm64,amd64"

# To avoid using 'docker manifest' (that is experimental), 
# allow buildx to manage push to registry for us.
# buildx manages build and push in one step
build-push: push-image

create-builder:
	# Workaround for buildx issue, see https://github.com/docker/buildx/issues/495#issuecomment-761562905
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name libsbuilder --driver docker-container --use
	docker buildx inspect --bootstrap

build-image: create-builder
	docker buildx build --platform $(ARCHS) -o type=image,push="false" .

push-image: create-builder
	docker buildx build --push --platform $(ARCHS) -t "$(IMAGE)" .

local-registry: create-builder
	docker buildx build --push --platform $(ARCHS) -t "localhost:5000/$(IMG_NAME)" .

sign-image: cosign
	$(cosign) sign --key $(cosign_key) $(IMAGE)

cosign: go
	@hash cosign 2>dev/null || \
		go install github.com/sigstore/cosign/cmd/cosign@v$(cosign_version)

go:
	@hash go 2>/dev/null || \
		>&2 echo "Go is needed." && exit 1
