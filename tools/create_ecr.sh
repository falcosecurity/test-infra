#!/bin/bash

export AWS_DEFAULT_REGION=eu-west-1

aws ecr create-repository --repository-name test-infra/update-jobs || true
aws ecr create-repository --repository-name test-infra/golang || true
