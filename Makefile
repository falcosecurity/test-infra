
@@ -1,3 +1,17 @@
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 The Falco Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#

SHELL := /bin/bash

include $(PWD)/tools/terraform.Makefile

.PHONY: oauth-token hmac-token github-oauth-config cookie plugins update-config

### Prow Components

update-jobs:
	@$(MAKE) -C prow/update-jobs build
	prow/update-jobs/bin/update-jobs --kubeconfig $$HOME/.kube/config --jobs-config-path config/jobs/

oauth-token:
	kubectl create secret generic oauth-token --from-literal=oauth="$${PROW_OAUTH_TOKEN}" --dry-run -o yaml | kubectl replace secret oauth-token -f -

hmac-token:
	kubectl create secret generic hmac-token --from-literal=hmac="$${PROW_HMAC_TOKEN}" --dry-run -o yaml | kubectl replace secret hmac-token -f -

github-oauth-config:
	kubectl create secret generic github-oauth-config --from-file=secret=./config/prow/github_oauth" --dry-run -o yaml | kubectl replace secret github-oauth-config -f -

cookie:
	kubectl create secret generic cookie --from-file=secret=./config/prow/cookie.txt" --dry-run -o yaml | kubectl replace secret cookie -f -

plugins:
	kubectl create configmap plugins --from-file=plugins.yaml=config/plugins.yaml --dry-run -o yaml | kubectl replace configmap plugins -f -

update-config:
	kubectl create configmap config --from-file=config.yaml=config/config.yaml --dry-run -o yaml | kubectl replace configmap config -f -

prow-s3-credentials:
	kubectl create secret generic s3-credentials --from-literal=service-account.json="$${PROW_SERVICE_ACCOUNT_JSON}" --dry-run -o yaml | kubectl replace secret s3-credentials -f -

prow:
	kubectl apply -f config/prow/

kubeconfig:
	aws eks --region eu-west-1 update-kubeconfig --name falco-prow-test-infra --profile default
