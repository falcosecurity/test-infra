package cmd

import (
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/cmd/autogenerate"
	logger "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"log"
)

var (
	rootCmd = &cobra.Command{
		Use:           "dbg-go",
		Short:         "A command line helper tool used by falcosecurity test-infra dbg.",
		SilenceErrors: true,
		SilenceUsage:  true,
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			if err := viper.BindPFlags(cmd.Flags()); err != nil {
				return err
			}
			return initLogger()
		},
	}
)

// NewRootCmd instantiates the root command.
func init() {
	flags := rootCmd.PersistentFlags()
	flags.Bool("dry-run", false, "enable dry-run mode.")
	flags.StringP("log-level", "l", logger.InfoLevel.String(), "set log verbosity.")
	flags.String("repo-root", "", "test-infra repository root path.")

	if err := rootCmd.MarkPersistentFlagRequired("repo-root"); err != nil {
		log.Fatal(err)
	}

	// Subcommands
	rootCmd.AddCommand(autogenerate.Cmd)
}

func initLogger() error {
	logLevel := viper.GetString("log-level")
	lvl, err := logger.ParseLevel(logLevel)
	if err != nil {
		return err
	}
	logger.SetLevel(lvl)
	return nil
}

func Execute() error {
	return rootCmd.Execute()
}
