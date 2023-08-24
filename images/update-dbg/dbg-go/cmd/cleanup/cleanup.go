package cleanup

import (
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/cleanup"
	"github.com/falcosecurity/test-infra/images/update-dbg/dbg-go/pkg/root"
	"github.com/spf13/cobra"
)

var (
	Cmd = &cobra.Command{
		Use:   "cleanup",
		Short: "Cleanup outdated dbg configs",
		RunE:  execute,
	}
)

func execute(c *cobra.Command, args []string) error {
	return cleanup.Run(cleanup.Options{Options: root.LoadRootOptions()})
}
