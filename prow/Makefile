SHELL := /bin/bash

cluster/oauth-token.yaml: oauth_secret
	kubectl create secret generic --dry-run -o yaml oauth-token --from-file=$< >> $@

cluster/hmac-token.yaml: hmac_secret
	kubectl create secret generic --dry-run -o yaml hmac-token --from-file=$< >> $@

prow: cluster/oauth-token.yaml cluster/hmac-token.yaml cluster/*.yaml
	kubectl apply -f cluster

plugins: config/plugins.yaml
	kubectl create configmap plugins --from-file=plugins.yaml=config/plugins.yaml --dry-run -o yaml | kubectl replace configmap plugins -f -

configs: config/configs.yaml
	kubectl create configmap configs --from-file=configs.yaml=config/configs.yaml --dry-run -o yaml | kubectl replace configmap configs -f -
