# SPDX-License-Identifier: Apache-2.0
# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SHELL=/bin/bash -o pipefail

export PATH

expose-gobin:
	$(eval PATH=${PATH}:$(shell go env GOPATH)/bin)

grafana-dashboards: install clean-dashboard-out node-mixin
	@mkdir -p dashboards_out
	@for input in $(shell ls grafana_dashboards); do \
		if [[ ! $${input} =~ .*\.jsonnet ]]; then \
			continue; \
		fi; \
		output="$${input%.*}.json"; \
		echo "Generating $${output} from $${input} ..."; \
		jsonnet -J vendor/ -J lib/ "grafana_dashboards/$${input}" > "./dashboards_out/$${output}"; \
	done
	@cp vendor/node-mixin/dashboards_out/* ./dashboards_out/

node-mixin:
	@make -C vendor/node-mixin build

prow_prometheusrule.yaml: install clean-prometheus-out
	@mkdir -p prometheus_out
	@echo "Generating prow_prometheusrule.yaml ..."
	jsonnet -J lib/ ./prometheus/prow_prometheusrule.jsonnet | gojsontoyaml > prometheus_out/$@

node_prometheusrule.yaml: install clean-prometheus-out node-mixin
	@cp vendor/node-mixin/prometheusrule.yaml prometheus_out/$@

apply-configmaps: grafana-dashboards
	@for input in $(shell ls dashboards_out); do \
		if [[ ! $${input} =~ .*\.json ]]; then \
			continue; \
		fi; \
		dashboard_name="grafana-dashboard-$${input%.*}"; \
		echo "Generating dashboard $${dashboard_name} from $${input} ..."; \
		kubectl create configmap -n prow-monitoring "$${dashboard_name}" --from-file="$${input}=dashboards_out/$${input}" --dry-run -o yaml | kubectl apply -f -; \
	done

apply-prometheusrules: prow_prometheusrule.yaml node_prometheusrule.yaml
	kubectl apply -f prometheus_out/

apply: apply-configmaps apply-prometheusrules clean

clean-dashboard-out:
	rm -rfv ./dashboards_out/*.json

clean-prometheus-out:
	rm -rfv ./prometheus_out/*.json
	rm -rfv ./prometheus_out/*.yaml

clean: clean-dashboard-out clean-prometheus-out

install: expose-gobin
	@if ! command -v jsonnet>/dev/null; then \
	  echo "Install jsonnet"; \
	  go install github.com/google/go-jsonnet/cmd/jsonnet@v0.17.0; \
	fi
	@ if ! command -v gojsontoyaml>/dev/null; then \
	  echo "Install gojsontoyaml"; \
	  go install github.com/brancz/gojsontoyaml@v0.1.0; \
	fi

.PHONY: expose-gobin grafana-dashboards prow_prometheusrule.yaml apply-configmaps apply-prometheusrules apply clean-dashboard-out clean-prometheus-out clean install
