this_path := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

IMG_SLUG := test-infra
IMG_NAME = docker-dind
TAG?=latest

include $(this_path)/../common.Makefile
