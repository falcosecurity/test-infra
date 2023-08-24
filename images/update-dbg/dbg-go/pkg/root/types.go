package root

import (
	logger "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

type Options struct {
	DryRun        bool
	RepoRoot      string
	Architecture  string
	DriverVersion []string
}

func LoadRootOptions() Options {
	opts := Options{
		DryRun:        viper.GetBool("dry-run"),
		RepoRoot:      viper.GetString("repo-root"),
		Architecture:  viper.GetString("architecture"),
		DriverVersion: viper.GetStringSlice("driver-version"),
	}
	logger.WithField("cmd", "root").Debugf("root options: %+v", opts)
	return opts
}
