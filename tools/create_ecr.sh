#!/bin/bash

export AWS_DEFAULT_REGION=eu-west-1

aws ecr create-repository --repository-name test-infra/update-jobs || true
aws ecr create-repository --repository-name test-infra/golang || true
aws ecr create-repository --repository-name test-infra/build-drivers || true
aws ecr create-repository --repository-name test-infra/docker-dind || true
aws ecr create-repository --repository-name test-infra/autobump || true



