package main

import (
	"context"
	"flag"
	"github.com/google/go-github/v61/github"
	"github.com/lmittmann/tint"
	"log/slog"
	"os"
	"sigs.k8s.io/prow/pkg/config"
	"strconv"
	"strings"
	"time"
)

var (
	jobConfigPath  *string
	prowConfigPath *string
	changed        *string
	ref            *string
	verbose        *bool
	authToken      *string

	client              *github.Client
	defaultBranchByRepo map[string]string
)

func init() {
	jobConfigPath = flag.String("config-job", "config/jobs/", "Path to the prow job config file or a folder full of prow jobs config files.")
	prowConfigPath = flag.String("config-prow", "config/config.yaml", "Path to the prow main config file")
	changed = flag.String("changed-file", "", "Changed file to check run against")
	ref = flag.String("base-ref", "", "Changed ref to check run against")
	verbose = flag.Bool("verbose", false, "Enable verbose logging")
	authToken = flag.String("token", "", "Github token used for GetRepo calls. Only useful when base-ref is not passed.")
}

func initLogger() {
	level := slog.LevelInfo
	if *verbose {
		level = slog.LevelDebug
	}
	// SetArgs proxies the arguments to the underlying cobra.Command.
	h := tint.NewHandler(os.Stdout, &tint.Options{
		Level:      level,
		TimeFormat: time.Kitchen,
	})
	slog.SetDefault(slog.New(h))
}

func ensureDefaultBranchCached(logger *slog.Logger, repo string) {
	if _, ok := defaultBranchByRepo[repo]; !ok {
		repos := strings.Split(repo, "/")
		r, _, err := client.Repositories.Get(context.Background(), repos[0], repos[1])
		if err != nil {
			logger.Error("Failed to fetch repo info", "err", err)
		} else {
			// cache default branch
			defaultBranchByRepo[repo] = *r.DefaultBranch
		}
	}
}

func main() {
	flag.Parse()
	initLogger()

	// If --base-ref is not passed, try to automatically load
	// default branch using a github client.
	if *ref == "" {
		if *authToken != "" {
			client = github.NewClient(nil).WithAuthToken(*authToken)
		} else {
			slog.Warn("Unauthenticated clients have lower rate limit")
			client = github.NewClient(nil)
		}
	}
	defaultBranchByRepo = make(map[string]string)

	slog.Debug("Generating config structure.")
	cfg, err := config.LoadStrict(*prowConfigPath, *jobConfigPath, nil, "")
	if err != nil {
		slog.Error("Failed to parse configuration", "err", err)
		os.Exit(1)
	}

	slog.Debug("Checking configured repositories.")
	for repo := range cfg.JobConfig.AllRepos {
		slog.Debug("Configured.", "repo", repo)
		if *ref != "" {
			defaultBranchByRepo[repo] = *ref
		}
	}

	slog.Debug("Starting validation.")
	for repo, preSubmits := range cfg.JobConfig.PresubmitsStatic {
		logger := slog.With("job-repo", repo, "job-kind", "presubmit")
		for _, preSubmit := range preSubmits {
			jobLogger := logger.With("job-name", preSubmit.Name)
			if err = preSubmit.Validate(); err != nil {
				jobLogger.Error("Failed to validate", "err", err)
				os.Exit(1)
			} else {
				jobLogger.Info("Successfully validated")
				// Only check for runChanged if `changed` is not empty
				if *changed != "" {
					ensureDefaultBranchCached(jobLogger, repo)
					runChanged := preSubmit.RunsAgainstChanges([]string{*changed})
					couldRun := preSubmit.CouldRun(defaultBranchByRepo[repo])
					jobLogger.Info("Would run: "+strconv.FormatBool(runChanged && couldRun), "ref", defaultBranchByRepo[repo], "changed-file", *changed)
				}
			}
		}
	}

	for repo, postSubmits := range cfg.JobConfig.PostsubmitsStatic {
		logger := slog.With("job-repo", repo, "job-kind", "postsubmit")
		for _, postSubmit := range postSubmits {
			jobLogger := logger.With("job-name", postSubmit.Name)
			if err = postSubmit.Validate(); err != nil {
				jobLogger.Error("Failed to validate", "err", err)
				os.Exit(1)
			} else {
				jobLogger.Info("Successfully validated")
				// Only account for runChanged if `changed` is not empty
				if *changed != "" {
					ensureDefaultBranchCached(logger, repo)
					runChanged := postSubmit.RunsAgainstChanges([]string{*changed})
					couldRun := postSubmit.CouldRun(defaultBranchByRepo[repo])
					jobLogger.Info("Would run: "+strconv.FormatBool(runChanged && couldRun), "ref", defaultBranchByRepo[repo], "changed-file", *changed)
				}
			}
		}
	}
	slog.Debug("End of validation.")
}
