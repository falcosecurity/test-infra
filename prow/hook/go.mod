module github.com/falcosecurity/hook

go 1.15

require (
	github.com/prometheus/client_golang v1.9.0
	github.com/sirupsen/logrus v1.7.0
	k8s.io/test-infra v0.0.0-20210120162201-2e3f5124c354
)

replace (
	k8s.io/api => k8s.io/api v0.19.2
	k8s.io/client-go => k8s.io/client-go v0.19.2
)