package cleanup

import (
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/root"
	logger "github.com/sirupsen/logrus"
	"os"
)

func Run(opts Options) error {
	logger.Info("cleaning up existing config files")
	for _, driverVersion := range opts.DriverVersion {
		configPath := fmt.Sprintf(root.ConfigPathFmt,
			opts.RepoRoot,
			driverVersion,
			opts.Architecture,
			"")
		logger.Infof("removing folder: %s", configPath)
		if opts.DryRun {
			logger.Info("skipping because of dry-run.")
			continue
		}
		err := os.RemoveAll(configPath)
		if err != nil {
			return err
		}
	}
	return nil
}
