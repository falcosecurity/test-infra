SHELL := /bin/bash

# OCI image artifact variables
OCI_AWS_ECR_REGION ?= eu-west-1
OCI_AWS_ECR_ACCOUNT ?= 292999226676
OCI_AWS_ECR_NAME := dkr.ecr.$(OCI_AWS_ECR_REGION).amazonaws.com
OCI_AWS_ECR_REGISTRY := $(OCI_AWS_ECR_ACCOUNT).$(OCI_AWS_ECR_NAME)
OCI_IMG_REPOSITORY := test-infra/update-jobs
OCI_IMG_NAME := $(OCI_AWS_ECR_REGISTRY)/$(OCI_IMG_REPOSITORY)
OCI_IMG_TAG ?= latest

VERBOSE ?= 0
ifeq ($(VERBOSE), 0)
# Make is verbose in Linux: let's make it silent.
MAKEFLAGS += --silent
endif

PROJECTNAME := update-jobs
OUTPUT_BASE ?= $(shell pwd)
OUTPUT_DIR := bin
OUTPUT_PATH := $(OUTPUT_BASE)/$(OUTPUT_DIR)

# Go variables
GOFILES := $(wildcard *.go)

# Redirect error output to a file, so we can show it in development mode.
STDERR := "/tmp/.$(PROJECTNAME)-stderr.txt"

$(OUTPUT_PATH)/$(PROJECTNAME): $(GOFILES)

build: $(OUTPUT_PATH)/$(PROJECTNAME)
	@echo "  >  Building binary... "
	touch $(STDERR)
	rm $(STDERR)
	mkdir -p $(OUTPUT_PATH)
	go build -o "$(OUTPUT_PATH)/$(PROJECTNAME)" $(GOFILES) 2> $(STDERR)
	cat $(STDERR) | sed -e '1s/.*/\nError:\n/'  | sed 's/make\[.*/ /' | sed "/^/s/^/     /" 1>&2
	@echo "Compiled in: $(OUTPUT_PATH)/$(PROJECTNAME)"

.PHONY: test
test:
	@echo "  >  Executing tests..."
	env GOTRACEBACK=all go test ./...

.PHONY: clean
clean:
	@echo "  >  Cleaning build cache"
	rm $(OUTPUT_PATH)/$(PROJECTNAME) 2> /dev/null
	go clean

.PHONY: oci/build-push
oci/build-push: oci/build oci/push

.PHONY: oci/build
oci/build:
	docker build -t $(OCI_IMG_REPOSITORY) .

.PHONY: oci/push
oci/push:
	docker tag $(OCI_IMG_REPOSITORY) $(OCI_IMG_NAME):$(OCI_IMG_TAG)
	docker push $(OCI_IMG_NAME):$(OCI_IMG_TAG)

.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) \: 2>/dev/null \
		| awk -v RS= -F: '/^# File/,/^# Finished Make data base/ \
		{if ($$1 !~ "^[#.]") {print $$1}}' | sort | \
		egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
