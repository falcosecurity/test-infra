JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s

all: fmt node_alerts.yaml node_rules.yaml prometheusrule.yaml dashboards_out lint

build: clean node_alerts.yaml node_rules.yaml prometheusrule.yaml dashboards_out

fmt:
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		xargs -n 1 -- $(JSONNET_FMT) -i

node_alerts.yaml: mixin.libsonnet config.libsonnet $(wildcard alerts/*)
	jsonnet -S alerts.jsonnet > $@

node_rules.yaml: mixin.libsonnet config.libsonnet $(wildcard rules/*)
	jsonnet -S rules.jsonnet > $@

dashboards_out: mixin.libsonnet config.libsonnet $(wildcard dashboards/*)
	@mkdir -p dashboards_out
	jsonnet -J ../../../../../../vendor -J lib -m dashboards_out dashboards.jsonnet

prometheusrule.yaml: mixin.libsonnet config.libsonnet $(wildcard rules/*)
	@echo "Generating prometheusrule.yaml ..."
	jsonnet prometheusrule.jsonnet | gojsontoyaml > $@

lint: node_alerts.yaml node_rules.yaml
	find . -name 'vendor' -prune -o -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
		while read f; do \
			$(JSONNET_FMT) "$$f" | diff -u "$$f" -; \
		done

	promtool check rules node_alerts.yaml node_rules.yaml

.PHONY: jb_install
jb_install:
	jb install

clean:
	rm -rf dashboards_out node_alerts.yaml node_rules.yaml prometheusrule.yaml
