package cmd

import (
	"fmt"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/cmd/autogenerate"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/cmd/cleanup"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/cmd/validate"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/utils"
	logger "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"log"
	"os"
	"runtime"
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

			arch := viper.GetString("architecture")
			driverVersions := viper.GetStringSlice("driver-version")
			if !utils.IsArchSupported(arch) {
				return fmt.Errorf("arch %s is not supported", arch)
			}
			if len(driverVersions) == 0 {
				if err := loadDriverVersions(); err != nil {
					return err
				}
			}
			return initLogger(cmd.Name())
		},
	}
)

func loadDriverVersions() error {
	repoRoot := viper.GetString("repo-root")
	configPath := repoRoot + "/driverkit/config/"
	driverVersions := make([]string, 0)
	entries, err := os.ReadDir(configPath)
	if err != nil {
		return err
	}
	for _, e := range entries {
		if e.IsDir() {
			driverVersions = append(driverVersions, e.Name())
		}
	}

	if len(driverVersions) != 0 {
		viper.Set("driver-version", driverVersions)
		return nil
	}
	return fmt.Errorf("no driver versions found")
}

// NewRootCmd instantiates the root command.
func init() {
	cwd, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	flags := rootCmd.PersistentFlags()
	flags.Bool("dry-run", false, "enable dry-run mode.")
	flags.StringP("log-level", "l", logger.InfoLevel.String(), "set log verbosity.")
	flags.String("repo-root", cwd, "test-infra repository root path.")
	flags.StringP("architecture", "a", utils.FromDebArch(runtime.GOARCH), "architecture to run against.")
	flags.StringSlice("driver-version", nil, "driver versions to generate configs against.")

	// Subcommands
	rootCmd.AddCommand(autogenerate.Cmd)
	rootCmd.AddCommand(cleanup.Cmd)
	rootCmd.AddCommand(validate.Cmd)
}

type customLogger struct {
	cmdField  string
	formatter logger.Formatter
}

func (l customLogger) Format(entry *logger.Entry) ([]byte, error) {
	entry.Data["cmd"] = l.cmdField
	return l.formatter.Format(entry)
}

func initLogger(subcmd string) error {
	logLevel := viper.GetString("log-level")
	lvl, err := logger.ParseLevel(logLevel)
	if err != nil {
		return err
	}
	logger.SetLevel(lvl)

	// Set our custom formatter that adds the field [ "cmd": $currentCmd ]
	logger.SetFormatter(customLogger{
		cmdField:  subcmd,
		formatter: logger.StandardLogger().Formatter,
	})

	return nil
}

func Execute() error {
	return rootCmd.Execute()
}
