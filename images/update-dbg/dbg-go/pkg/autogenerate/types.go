package autogenerate

import (
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/root"
)

type Options struct {
	root.Options
	DriverName string
}

// KernelEntry is the json output from kernel-crawler schema
type KernelEntry struct {
	KernelVersion    string   `json:"kernelversion"`
	KernelRelease    string   `json:"kernelrelease"`
	Target           string   `json:"target"`
	Headers          []string `json:"headers"`
	KernelConfigData []byte   `json:"kernelconfigdata"`
}

func (ke *KernelEntry) ToConfigName() string {
	return fmt.Sprintf("%s_%s_%s.yaml", ke.Target, ke.KernelRelease, ke.KernelVersion)
}

type DriverkitYamlOutputs struct {
	Module string `yaml:"module"`
	Probe  string `yaml:"probe"`
}

// DriverkitYaml is the driverkit config schema
type DriverkitYaml struct {
	KernelVersion    string               `yaml:"kernelversion"`
	KernelRelease    string               `yaml:"kernelrelease"`
	Target           string               `yaml:"target"`
	Architecture     string               `yaml:"architecture"`
	Output           DriverkitYamlOutputs `yaml:"output"`
	KernelUrls       []string             `yaml:"kernelurls,omitempty"`
	KernelConfigData string               `yaml:"kernelconfigdata,omitempty"`
}
