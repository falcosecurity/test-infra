package cmd

import (
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/cmd/autogenerate"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	rootCmd = &cobra.Command{
		Use:           "dbg-go",
		Short:         "A command line helper tool used by falcosecurity test-infra dbg.",
		SilenceErrors: true,
		SilenceUsage:  true,
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			return viper.BindPFlags(cmd.Flags())
		},
	}
)

// NewRootCmd instantiates the root command.
func init() {
	flags := rootCmd.PersistentFlags()
	flags.Bool("dry-run", false, "enable dry-run mode.")

	// Subcommands
	rootCmd.AddCommand(autogenerate.Cmd)
}

func Execute() error {
	return rootCmd.Execute()
}
