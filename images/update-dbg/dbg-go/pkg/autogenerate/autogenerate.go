package autogenerate

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/utils"
	"gopkg.in/yaml.v3"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
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

	// load output dirs
	outputDirs := make([]string, 0)
	err = filepath.WalkDir(opts.OutputRoot, func(path string, d fs.DirEntry, err error) error {
		if !d.Type().IsDir() {
			// Skip non-dir entries
			return nil
		}
		if opts.DriverVersion == nil || len(opts.DriverVersion) == 0 {
			// no filter; use all directories
			outputDirs = append(outputDirs, path)
			return nil
		}
		for _, driverVer := range opts.DriverVersion {
			// Filter, match!
			if d.Name() == driverVer {
				outputDirs = append(outputDirs, path)
				break
			}
		}
		return nil
	})
	if err != nil {
		return err
	}

	// Fetch kernel list json
	jsonData, err := utils.GetURL(url)
	//jsonData, err := os.ReadFile("/home/federico/Scaricati/kernels.json")
	if err != nil {
		return err
	}

	// Unmarshal the big json
	var kernelList KernelList
	err = json.Unmarshal(jsonData, &kernelList)
	if err != nil {
		return err
	}

	v := reflect.ValueOf(kernelList)
	typeOfS := v.Type()

	for i := 0; i < v.NumField(); i++ {
		if lastDistro != "*" && typeOfS.Field(i).Name != lastDistro {
			continue
		}
		kernelEntries := v.Field(i).Interface().([]KernelEntry)
		for _, kernelEntry := range kernelEntries {
			driverkitYaml := DriverkitYaml{
				KernelVersion:    kernelEntry.KernelVersion,
				KernelRelease:    kernelEntry.KernelRelease,
				Target:           kernelEntry.Target,
				Architecture:     utils.ToDebArch(opts.Architecture),
				KernelUrls:       kernelEntry.Headers,
				KernelConfigData: kernelEntry.KernelConfigData,
			}

			for _, oDir := range outputDirs {
				// FIXME! use correct path (inside folder) https://github.com/falcosecurity/test-infra/blob/master/driverkit/utils/generate#L93
				fW, err := os.OpenFile(oDir, os.O_CREATE|os.O_RDWR, os.ModePerm)
				if err != nil {
					return err
				}
				driverkitYaml.Output = DriverkitYamlOutputs{
					// FIXME: oDir is wrong here... see https://github.com/falcosecurity/test-infra/blob/master/driverkit/utils/generate#L93
					Module: fmt.Sprintf(outputPathFmt+".ko", oDir, kernelEntry.Target, kernelEntry.KernelRelease+"_"+kernelEntry.KernelVersion),
					Probe:  fmt.Sprintf(outputPathFmt+".o", oDir, kernelEntry.Target, kernelEntry.KernelRelease+"_"+kernelEntry.KernelVersion),
				}

				yamlData, err := yaml.Marshal(&driverkitYaml)
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
