package autogenerate

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/root"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/utils"
	"github.com/ompluscator/dynamic-struct"
	logger "github.com/sirupsen/logrus"
	"golang.org/x/sync/errgroup"
	"gopkg.in/yaml.v3"
	"os"
	"path/filepath"
	"strings"
	"text/template"
)

func initTemplate(opts Options) (string, error) {
	t := template.New("autogenerate")
	parsed, err := t.Parse(urlArchTemplate)
	if err != nil {
		return "", err
	}

	buf := bytes.NewBuffer(nil)
	err = parsed.Execute(buf, &opts)
	return buf.String(), err
}

func Run(opts Options) error {
	url, err := initTemplate(opts)
	if err != nil {
		return err
	}
	logger.Debug("templated json url: ", url)

	// Fetch last distro kernel-crawler was last ran against
	lastDistroBytes, err := utils.GetURL(urlLastDistro)
	if err != nil {
		return err
	}
	lastDistro := strings.TrimSuffix(string(lastDistroBytes), "\n")
	logger.Debug("loaded last-distro: ", lastDistro)

	// Fetch kernel list json
	jsonData, err := utils.GetURL(url)
	if err != nil {
		return err
	}
	logger.Debug("fetched json")

	// Generate a dynamic struct with all needed distros
	// NOTE: we might need a single distro when `lastDistro` is != "*";
	// else, we will add all supportedDistros found in constants.go
	instanceBuilder := dynamicstruct.NewStruct()
	for _, distro := range supportedDistros {
		if lastDistro == "*" || distro == lastDistro {
			tag := fmt.Sprintf(`json:"%s"`, distro)
			instanceBuilder.AddField(distro, []KernelEntry{}, tag)
		}
	}
	dynamicInstance := instanceBuilder.Build().New()

	// Unmarshal the big json
	err = json.Unmarshal(jsonData, &dynamicInstance)
	if err != nil {
		return err
	}
	logger.Debug("unmarshaled json")

	var errGrp errgroup.Group

	reader := dynamicstruct.NewReader(dynamicInstance)
	for _, f := range reader.GetAllFields() {
		logger.Infof("generating configs for %s\n", f.Name())
		if opts.DryRun {
			logger.Info("skipping because of dry-run.")
			continue
		}
		kernelEntries := f.Interface().([]KernelEntry)
		// A goroutine for each distro
		errGrp.Go(func() error {
			for _, kernelEntry := range kernelEntries {
				driverkitYaml := DriverkitYaml{
					KernelVersion:    kernelEntry.KernelVersion,
					KernelRelease:    kernelEntry.KernelRelease,
					Target:           kernelEntry.Target,
					Architecture:     utils.ToDebArch(opts.Architecture),
					KernelUrls:       kernelEntry.Headers,
					KernelConfigData: string(kernelEntry.KernelConfigData),
				}

				kernelEntryConfName := kernelEntry.ToConfigName()

				for _, driverVersion := range opts.DriverVersion {
					outputPath := fmt.Sprintf(OutputPathFmt,
						driverVersion,
						opts.Architecture,
						opts.DriverName,
						kernelEntry.Target,
						kernelEntry.KernelRelease,
						kernelEntry.KernelVersion)
					driverkitYaml.Output = DriverkitYamlOutputs{
						Module: outputPath + ".ko",
						Probe:  outputPath + ".o",
					}
					yamlData, pvtErr := yaml.Marshal(&driverkitYaml)
					if pvtErr != nil {
						return pvtErr
					}

					configPath := fmt.Sprintf(root.ConfigPathFmt,
						opts.RepoRoot,
						driverVersion,
						opts.Architecture,
						kernelEntryConfName)

					// Make sure folder exists
					pvtErr = os.MkdirAll(filepath.Dir(configPath), os.ModePerm)
					if pvtErr != nil {
						return pvtErr
					}
					fW, pvtErr := os.OpenFile(configPath, os.O_CREATE|os.O_RDWR, os.ModePerm)
					if pvtErr != nil {
						return pvtErr
					}
					_, _ = fW.Write(yamlData)
					_ = fW.Close()
				}
			}
			return nil
		})
	}
	return errGrp.Wait()
}
