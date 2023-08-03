package autogenerate

import (
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/autogenerate"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/root"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/utils"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"io/fs"
	"log"
	"path/filepath"
	"runtime"
)

var (
	Cmd = &cobra.Command{
		Use:   "autogenerate",
		Short: "Fetch updated kernel-crawler lists and generate new dbg configs",
		RunE:  execute,
		PreRunE: func(cmd *cobra.Command, args []string) error {
			return viper.BindPFlags(cmd.Flags())
		},
	}
)

func mustLoadDriverVersions(opts *autogenerate.Options) {
	configPath := opts.RepoRoot + "/driverkit/config/"
	opts.DriverVersion = make([]string, 0)
	err := filepath.WalkDir(configPath, func(path string, d fs.DirEntry, err error) error {
		if d.IsDir() {
			opts.DriverVersion = append(opts.DriverVersion, d.Name())
		}
		return nil
	})
	if err != nil {
		log.Fatal(err)
	}
}

func execute(c *cobra.Command, args []string) error {
	options := autogenerate.Options{
		Options:       root.Options{DryRun: viper.GetBool("dry-run"), RepoRoot: viper.GetString("repo-root")},
		Architecture:  viper.GetString("architecture"),
		DriverVersion: viper.GetStringSlice("driver-version"),
		DriverName:    viper.GetString("driver-name"),
	}
	if !utils.IsArchSupported(options.Architecture) {
		return fmt.Errorf("arch %s is not supported", options.Architecture)
	}
	if len(options.DriverVersion) == 0 {
		mustLoadDriverVersions(&options)
	}
	return autogenerate.Run(options)
}

func init() {
	flags := Cmd.Flags()
	flags.StringP("architecture", "a", utils.FromDebArch(runtime.GOARCH), "architecture to run against.")
	flags.StringSlice("driver-version", nil, "driver versions to generate configs against.")
	flags.String("driver-name", "falco", "driver name to be used")
}
