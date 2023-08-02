package autogenerate

import (
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/autogenerate"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/root"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/utils"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
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

func execute(c *cobra.Command, args []string) error {
	options := autogenerate.Options{
		Options:       root.Options{DryRun: viper.GetBool("dry-run")},
		Architecture:  viper.GetString("architecture"),
		DriverVersion: viper.GetStringSlice("driver-version"),
		OutputRoot:    viper.GetString("output-dir"),
	}
	if !utils.IsArchSupported(options.Architecture) {
		return fmt.Errorf("arch %s is not supported", options.Architecture)
	}
	return autogenerate.Run(options)
}

func init() {
	flags := Cmd.Flags()
	flags.StringP("architecture", "a", "x86_64", "architecture to run against.")
	flags.String("output-dir", "config/", "output root path.")
	flags.StringSlice("driver-version", nil, "driver versions to generate configs against.")
}
