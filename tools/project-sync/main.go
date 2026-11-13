// SPDX-License-Identifier: Apache-2.0
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
	proworg "sigs.k8s.io/prow/pkg/config/org"
	prowyaml "sigs.k8s.io/yaml"
)

type options struct {
	Project, Evolution, TestInfra, Snapshot, Org, Retire, TokenFile, Output, WorkDir, GPGKey string
	Write, Publish                                                                           bool
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "project-sync:", err)
		os.Exit(1)
	}
}
func run(args []string) error {
	if len(args) == 0 {
		return fmt.Errorf("usage: project-sync {snapshot|accounts|migrate|reconcile|render|jobs|validate|sync} [flags]")
	}
	command := args[0]
	var o options
	fs := flag.NewFlagSet(command, flag.ContinueOnError)
	fs.StringVar(&o.Project, "project-dir", ".", "local .project checkout")
	fs.StringVar(&o.Evolution, "evolution-dir", "", "local evolution checkout")
	fs.StringVar(&o.TestInfra, "test-infra-dir", "", "local test-infra checkout for generated triggers")
	fs.StringVar(&o.Snapshot, "snapshot", "", "read an immutable OWNERS snapshot instead of GitHub")
	fs.StringVar(&o.Org, "source-org", "", "legacy test-infra config/org.yaml (migration only)")
	fs.StringVar(&o.Retire, "retire", "", "planned repository retirement to exclude from a local migration preview only")
	fs.StringVar(&o.TokenFile, "github-token-path", "", "GitHub token file; otherwise GH_TOKEN")
	fs.StringVar(&o.Output, "output", "", "snapshot output path")
	fs.StringVar(&o.WorkDir, "work-dir", "", "temporary Git checkout parent directory")
	fs.StringVar(&o.GPGKey, "gpg-key", "", "bot private GPG key file, required for publishing")
	fs.BoolVar(&o.Write, "write", false, "write local generated files (default: report only)")
	fs.BoolVar(&o.Publish, "publish", false, "publish bot PRs (sync command only)")
	if err := fs.Parse(args[1:]); err != nil {
		return err
	}
	if fs.NArg() != 0 {
		return fmt.Errorf("unexpected positional arguments")
	}
	if o.Publish && command != "sync" {
		return fmt.Errorf("--publish is only supported by sync")
	}
	if o.Retire != "" && command != "migrate" {
		return fmt.Errorf("--retire is only supported by local migration")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Minute)
	defer cancel()
	if command == "sync" {
		g, err := githubFromOptions(o)
		if err != nil {
			return err
		}
		return synchronize(ctx, g, o)
	}
	if command == "snapshot" {
		if o.Output == "" {
			return fmt.Errorf("--output required")
		}
		g, err := githubFromOptions(o)
		if err != nil {
			return err
		}
		s, err := g.snapshot(ctx)
		if err != nil {
			return err
		}
		b, err := json.MarshalIndent(s, "", "  ")
		if err != nil {
			return err
		}
		return os.WriteFile(o.Output, append(b, '\n'), 0644)
	}
	if command == "accounts" {
		if o.Snapshot == "" || o.Output == "" {
			return fmt.Errorf("--snapshot and --output required")
		}
		s, e := readSnapshot(o.Snapshot)
		if e != nil {
			return e
		}
		g, e := githubFromOptions(o)
		if e != nil {
			return e
		}
		if e = g.accounts(ctx, &s); e != nil {
			return e
		}
		b, e := json.MarshalIndent(s, "", "  ")
		if e != nil {
			return e
		}
		return os.WriteFile(o.Output, append(b, '\n'), 0644)
	}
	if command == "migrate" {
		return migrate(o)
	}
	p, err := loadProject(o.Project)
	if err != nil {
		return err
	}
	switch command {
	case "jobs":
		if o.TestInfra == "" {
			return fmt.Errorf("--test-infra-dir required")
		}
		r, e := renderJobs(p)
		if e != nil {
			return e
		}
		changed, e := applyResult(o.TestInfra, r, o.Write)
		fmt.Println("Trigger changes:", changed)
		return e
	case "validate":
		return validateEditable(p)
	case "render":
		if o.Evolution == "" {
			return fmt.Errorf("--evolution-dir required")
		}
		changed, e := render(p, o.Evolution, o.Write)
		fmt.Println("Documentation changes:", changed)
		return e
	case "reconcile":
		if o.Snapshot == "" {
			return fmt.Errorf("--snapshot required; use snapshot or sync to retrieve GitHub state")
		}
		s, e := readSnapshot(o.Snapshot)
		if e != nil {
			return e
		}
		r, e := reconcile(p, s)
		if e != nil {
			return e
		}
		changed, e := applyResult(o.Project, r, o.Write)
		for _, line := range r.Summary {
			fmt.Println(line)
		}
		fmt.Println("Metadata changes:", changed)
		return e
	default:
		return fmt.Errorf("unknown command %q", command)
	}
}
func githubFromOptions(o options) (*GitHub, error) {
	token := strings.TrimSpace(os.Getenv("GH_TOKEN"))
	if o.TokenFile != "" {
		b, e := os.ReadFile(o.TokenFile)
		if e != nil {
			return nil, e
		}
		token = strings.TrimSpace(string(b))
	}
	if token == "" {
		return nil, fmt.Errorf("GH_TOKEN or --github-token-path required")
	}
	return &GitHub{Token: token}, nil
}
func migrate(o options) error {
	if o.Org == "" || o.Evolution == "" || o.Snapshot == "" {
		return fmt.Errorf("migration needs --source-org, --evolution-dir, and --snapshot")
	}
	s, err := readSnapshot(o.Snapshot)
	if err != nil {
		return err
	}
	if o.Retire != "" {
		r, ok := s.Repositories[o.Retire]
		if !ok {
			return fmt.Errorf("unknown retirement %s", o.Retire)
		}
		r.Archived = true
		s.Repositories[o.Retire] = r
		fmt.Println("Planned retirement excluded from local preview:", o.Retire, "(GitHub unchanged)")
	}
	b, err := os.ReadFile(o.Org)
	if err != nil {
		return err
	}
	p := &Project{Dir: o.Project, OrgDocument: &yaml.Node{}}
	if err = yaml.Unmarshal(b, p.OrgDocument); err != nil {
		return err
	}
	var cfg proworg.FullConfig
	if err = prowyaml.UnmarshalStrict(b, &cfg); err != nil {
		return err
	}
	p.Org = cfg.Orgs[organization]
	var legacy []struct {
		Name        string `yaml:"name"`
		Scope       string `yaml:"scope"`
		Status      string `yaml:"status"`
		Description string `yaml:"description"`
	}
	if err = loadYAML(filepath.Join(o.Evolution, "repositories.yaml"), &legacy); err != nil {
		return err
	}
	orgRepos := field(field(field(p.OrgDocument, "orgs"), organization), "repos")
	for _, repo := range legacy {
		p.Catalog = append(p.Catalog, Repository{repo.Name, repo.Scope, repo.Status})
		if err = put(ensureMap(orgRepos, repo.Name), "description", repo.Description); err != nil {
			return err
		}
	}
	found := false
	for _, r := range p.Catalog {
		if r.Name == ".project" {
			found = true
		}
	}
	if !found {
		p.Catalog = append(p.Catalog, Repository{Name: ".project", Scope: "Special"})
	}
	b, err = os.ReadFile(filepath.Join(o.Evolution, "people/affiliations.json"))
	if err != nil {
		return err
	}
	if err = json.Unmarshal(b, &p.Affiliations); err != nil {
		return err
	}
	r, err := reconcile(p, s)
	if err != nil {
		return err
	}
	changed, err := applyResult(o.Project, r, o.Write)
	for _, line := range r.Summary {
		fmt.Println(line)
	}
	fmt.Println("Migration changes:", changed)
	return err
}
