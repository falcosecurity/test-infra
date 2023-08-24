package validate

import (
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/autogenerate"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/root"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/utils"
	logger "github.com/sirupsen/logrus"
	"gopkg.in/yaml.v3"
	"os"
	"path/filepath"
	"strings"
)

func Run(opts Options) error {
	logger.Info("validate config files")
	for _, driverVersion := range opts.DriverVersion {
		configPath := fmt.Sprintf(root.ConfigPathFmt,
			opts.RepoRoot,
			driverVersion,
			opts.Architecture,
			"")
		configs, _ := os.ReadDir(configPath)
		for _, config := range configs {
			configFilepath := filepath.Join(configPath, config.Name())
			logger.Infof("validating config: %s", configFilepath)
			if opts.DryRun {
				logger.Info("skipping because of dry-run.")
				continue
			}
			if err := validateConfig(opts, driverVersion, configFilepath); err != nil {
				return err
			}
		}
	}
	return nil
}

func validateConfig(opts Options, driverVersion, configPath string) error {
	configData, err := os.ReadFile(configPath)
	if err != nil {
		return err
	}
	var driverkitYaml autogenerate.DriverkitYaml
	err = yaml.Unmarshal(configData, &driverkitYaml)
	if err != nil {
		return err
	}

	// Check that filename is ok
	kernelEntry := autogenerate.KernelEntry{
		KernelVersion:    driverkitYaml.KernelVersion,
		KernelRelease:    driverkitYaml.KernelRelease,
		Target:           driverkitYaml.Target,
		Headers:          driverkitYaml.KernelUrls,
		KernelConfigData: []byte(driverkitYaml.KernelConfigData),
	}
	expectedFilename := kernelEntry.ToConfigName()
	configFilename := filepath.Base(configPath)
	if configFilename != expectedFilename {
		return fmt.Errorf("config filename is wrong (%s); should be %s", configFilename, expectedFilename)
	}

	// Check that arch is ok
	goArch := utils.ToDebArch(opts.Architecture)
	if driverkitYaml.Architecture != goArch {
		return fmt.Errorf("wrong architecture in config file: %s", configPath)
	}

	outputPath := fmt.Sprintf(autogenerate.OutputPathFmt,
		driverVersion,
		opts.Architecture,
		"falco",
		kernelEntry.Target,
		kernelEntry.KernelRelease,
		kernelEntry.KernelVersion)

	outputPathFilename := filepath.Base(outputPath)

	// Check output probe if present
	if len(driverkitYaml.Output.Probe) > 0 {
		outputProbeFilename := filepath.Base(driverkitYaml.Output.Probe)
		if outputProbeFilename != outputPathFilename+".o" {
			return fmt.Errorf("output probe filename is wrong (%s); expected: %s.o", outputProbeFilename, outputPathFilename)
		}

		if !strings.Contains(driverkitYaml.Output.Probe, opts.Architecture) {
			return fmt.Errorf("output probe filename has wrong architecture in its path (%s); expected %s",
				driverkitYaml.Output.Probe, opts.Architecture)
		}
	}

	// Check output driver if present
	if len(driverkitYaml.Output.Module) > 0 {
		outputModuleFilename := filepath.Base(driverkitYaml.Output.Module)
		if outputModuleFilename != outputPathFilename+".ko" {
			return fmt.Errorf("output module filename is wrong (%s); expected: %s.ko", outputModuleFilename, outputPathFilename)
		}

		if !strings.Contains(driverkitYaml.Output.Module, opts.Architecture) {
			return fmt.Errorf("output module filename has wrong architecture in its path (%s); expected %s",
				driverkitYaml.Output.Module, opts.Architecture)
		}
	}

	return nil
}
