module github.com/falcosecurity/test-infra/prow/update-jobs

go 1.15

replace (
	k8s.io/api => k8s.io/api v0.17.5
	k8s.io/apimachinery => k8s.io/apimachinery v0.17.5
	k8s.io/client-go => k8s.io/client-go v0.17.5
)

require (
	github.com/kyma-project/test-infra/development/tools v0.0.0-20201222115624-7486d35e2416
	github.com/pkg/errors v0.9.1
	github.com/sirupsen/logrus v1.8.3
	k8s.io/api v0.17.5
	k8s.io/apimachinery v0.17.5
	k8s.io/client-go v12.0.0+incompatible
)
