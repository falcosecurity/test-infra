module github.com/falcosecurity/pr-creator

go 1.13

replace (
	k8s.io/api => k8s.io/api v0.19.0
	k8s.io/apimachinery => k8s.io/apimachinery v0.19.5-rc.0
	k8s.io/client-go => k8s.io/client-go v0.19.0
)

require (
	github.com/sirupsen/logrus v1.7.0
	k8s.io/api v0.19.9
	k8s.io/apimachinery v0.19.3
	k8s.io/client-go v11.0.1-0.20190805182717-6502b5e7b1b5+incompatible
	k8s.io/test-infra v0.0.0-20201127122448-2c27a26f2e22
)
