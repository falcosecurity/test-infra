package autogenerate

import (
	"fmt"
	logger "github.com/sirupsen/logrus"
	"os"
)

func cleanupExisting(opts Options) error {
	logger.WithField("cmd", "autogenerate").Info("cleaning up existing config files")
	if opts.DryRun {
		logger.WithField("cmd", "autogenerate").Info("skipping because of dry-run.")
		return nil
	}
	for _, driverVersion := range opts.DriverVersion {
		configPath := fmt.Sprintf(configPathFmt,
			opts.RepoRoot,
			driverVersion,
			opts.Architecture,
			"")
		logger.WithField("cmd", "autogenerate").Debugf("removing folder: %s", configPath)
		err := os.RemoveAll(configPath)
		if err != nil {
			return err
		}
	}
	return nil
}
