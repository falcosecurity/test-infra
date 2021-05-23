SHELL=/bin/bash -o pipefail

all: grafana-dashboards prow_prometheusrule.yaml

grafana-dashboards:
	for name in deck ghproxy hook plank prow sinker slo tide; do echo "Generating $${name}.json ..."; jsonnet -J vendor/ -J lib/ "grafana_dashboards/$${name}.jsonnet" > "./dashboards_out/$${name}.json"; done

prow_prometheusrule.yaml:
	@echo "Generating prow_prometheusrule.yaml ..."
	jsonnet -J lib/ ./prometheus/prow_prometheusrule.jsonnet | gojsontoyaml > prometheus_out/$@

clean-vendor:
	rm -rfv ./vendor

clean:
	rm -rfv ./dashboards_out/*.json
	rm -rfv ./prometheus_out/*.json
	rm -rfv ./prometheus_out/*.yaml

install:
	jb install

pf-prom:
	kubectl -n prow-monitoring port-forward $$( kubectl -n prow-monitoring get pods --selector app=prometheus -o jsonpath={.items[0].metadata.name} ) 9090

pf-alertmanager:
	kubectl -n prow-monitoring port-forward $$( kubectl -n prow-monitoring get pods --selector app=alertmanager -o jsonpath={.items[0].metadata.name} ) 9093