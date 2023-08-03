package autogenerate

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/utils"
	"github.com/ompluscator/dynamic-struct"
	"gopkg.in/yaml.v3"
	"os"
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

	// Fetch last distro kernel-crawler was last ran against
	lastDistroBytes, err := utils.GetURL(urlLastDistro)
	if err != nil {
		return err
	}
	lastDistro := strings.TrimSuffix(string(lastDistroBytes), "\n")

	// Fetch kernel list json
	jsonData, err := utils.GetURL(url)
	if err != nil {
		return err
	}

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

	reader := dynamicstruct.NewReader(dynamicInstance)
	for _, f := range reader.GetAllFields() {
		kernelEntries := f.Interface().([]KernelEntry)
		for _, kernelEntry := range kernelEntries {
			driverkitYaml := DriverkitYaml{
				KernelVersion:    kernelEntry.KernelVersion,
				KernelRelease:    kernelEntry.KernelRelease,
				Target:           kernelEntry.Target,
				Architecture:     utils.ToDebArch(opts.Architecture),
				KernelUrls:       kernelEntry.Headers,
				KernelConfigData: kernelEntry.KernelConfigData,
			}

			kernelEntryConfName := kernelEntry.toConfigName()

			for _, driverVersion := range opts.DriverVersion {
				outputPath := fmt.Sprintf(outputPathFmt,
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
				yamlData, err := yaml.Marshal(&driverkitYaml)
				if err != nil {
					return err
				}

				configPath := fmt.Sprintf(configPathFmt,
					opts.RepoRoot,
					driverVersion,
					opts.Architecture,
					kernelEntryConfName)
				fW, err := os.OpenFile(configPath, os.O_CREATE|os.O_RDWR, os.ModePerm)
				if err != nil {
					return err
				}
				_, _ = fW.Write(yamlData)
				_ = fW.Close()
			}
		}
	}
	return nil
}
