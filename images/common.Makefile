SHELL := /usr/bin/env bash

bins := docker aws cosign go

# OCI artifact signing
cosign_version ?= 1.9.0
cosign_k8s_namespace := cosign
cosign_k8s_secret := openinfra-oci-sign
cosign_k8s_key := k8s://$(cosign_k8s_namespace)/$(cosign_k8s_secret)
cosign_key := $(cosign_k8s_key)

# OCI registry
AWS_ACCOUNT :=292999226676
AWS_REGION ?= eu-west-1
AWS_ECR_BASE := dkr.ecr.$(AWS_REGION).amazonaws.com
AWS_ECR := $(AWS_ACCOUNT).$(AWS_ECR_BASE)
REGISTRY ?= $(AWS_ECR)

# OCI repository
IMG_SLUG ?= test-infra
IMG_NAME ?=

# OCI image
IMG_TAG ?= latest
IMAGE := "$(REGISTRY)/$(IMG_SLUG)/$(IMG_NAME):$(IMG_TAG)"

all: build-image sign-image push-image

build-push: build-image push-image

build-image:
	$(docker) build --no-cache -t "$(IMG_SLUG)/$(IMG_NAME)" .

sign-image: cosign
	$(cosign) sign --key $(cosign_key) $(IMAGE)

push-image:
	$(docker) tag "$(IMG_SLUG)/$(IMG_NAME)" $(IMAGE)
	$(docker) push $(IMAGE)

login:
	@$(aws) ecr get-login-password \
	| $(docker) login \
		--username AWS \
		--password-stdin $(REGISTRY)

local-registry:
	$(docker) tag "$(IMG_SLUG)/$(IMG_NAME)" localhost:5000/$(IMG_NAME)
	$(docker) push localhost:5000/$(IMG_NAME)

cosign: go
	@hash cosign 2>/dev/null || \
		$(go) install github.com/sigstore/cosign/cmd/cosign@v$(cosign_version)

go:
	@hash go 2>/dev/null || \
		{ >&2 echo "Go is needed." && exit 1; }
	
define gen_binpath
$(1) := $(shell command -v $(1) 2>/dev/null)
endef

$(foreach bin,$(bins),\
	$(eval $(call gen_binpath,$(bin)))\
)
