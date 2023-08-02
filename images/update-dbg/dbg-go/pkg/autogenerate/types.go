package autogenerate

import "github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/root"

type Options struct {
	root.Options
	Architecture  string
	DriverVersion []string
	OutputRoot    string
}

type KernelEntry struct {
	KernelVersion    string   `json:"kernelversion"`
	KernelRelease    string   `json:"kernelrelease"`
	Target           string   `json:"target"`
	Headers          []string `json:"headers"`
	KernelConfigData []byte   `json:"kernelconfigdata"`
}

// Please add new supporteed build-new-drivers structures here,
// so that the utility starts building configs for them.
// Fields must have the same name used in kernel-crawler json keys.
type KernelList struct {
	AlmaLinux       []KernelEntry `json:"AlmaLinux"`
	AmazonLinux     []KernelEntry `json:"Amazonlinux"`
	AmazonLinux2    []KernelEntry `json:"Amazonlinux2"`
	AmazonLinux2022 []KernelEntry `json:"Amazonlinux2022"`
	AmazonLinux2023 []KernelEntry `json:"Amazonlinux2023"`
	BottleRocket    []KernelEntry `json:"BottleRocket"`
	CentOS          []KernelEntry `json:"CentOS"`
	Debian          []KernelEntry `json:"Debian"`
	Fedora          []KernelEntry `json:"Fedora"`
	Minikube        []KernelEntry `json:"Minikube"`
	Talos           []KernelEntry `json:"Talos"`
	Ubuntu          []KernelEntry `json:"Ubuntu"`
}

type DriverkitYamlOutputs struct {
	Module string `yaml:"module"`
	Probe  string `yaml:"probe"`
}

type DriverkitYaml struct {
	KernelVersion    string               `yaml:"kernelversion"`
	KernelRelease    string               `yaml:"kernelrelease"`
	Target           string               `yaml:"target"`
	Architecture     string               `yaml:"architecture"`
	Output           DriverkitYamlOutputs `yaml:"output"`
	KernelUrls       []string             `yaml:"kernelurls,omitempty"`
	KernelConfigData []byte               `yaml:"kernelconfigdata,omitempty"`
}
