//go:build integration

// SPDX-License-Identifier: Apache-2.0

package main

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"

	"sigs.k8s.io/yaml"
)

type checkerContainer struct {
	Image   string   `json:"image"`
	Command []string `json:"command"`
	Args    []string `json:"args"`
}

type checkerJob struct {
	Name string `json:"name"`
	Spec struct {
		Containers []checkerContainer `json:"containers"`
	} `json:"spec"`
}

func TestCheckconfigLayouts(t *testing.T) {
	// Read the actual job definitions, not a separately maintained shell copy.
	manifestPath := filepath.Join("..", "..", "config", "jobs", "check-prow-config", "check-prow-config.yaml")
	manifest, err := os.ReadFile(manifestPath)
	if err != nil {
		t.Fatal(err)
	}
	var config struct {
		Presubmits map[string][]checkerJob `json:"presubmits"`
		Periodics  []checkerJob            `json:"periodics"`
	}
	if err := yaml.Unmarshal(manifest, &config); err != nil {
		t.Fatal(err)
	}
	jobs := map[string]checkerContainer{}
	for _, job := range append(config.Presubmits["falcosecurity/test-infra"], config.Periodics...) {
		if job.Name != "check-prow-config" && job.Name != "check-prow-config-periodic" {
			continue
		}
		if len(job.Spec.Containers) != 1 || len(job.Spec.Containers[0].Command) == 0 {
			t.Fatalf("%s must define one container with an explicit command", job.Name)
		}
		jobs[job.Name] = job.Spec.Containers[0]
	}
	if len(jobs) != 2 {
		t.Fatal("Both the presubmit and periodic checker must be present")
	}
	images := map[string]bool{}
	for _, container := range jobs {
		if container.Image == "" {
			t.Fatal("Checker image is missing")
		}
		if !images[container.Image] {
			ensureCheckerImage(t, container.Image)
			images[container.Image] = true
		}
	}

	type layoutCase struct {
		name    string
		split   bool
		files   map[string]string
		remove  string
		wantErr bool
	}
	cases := []layoutCase{
		{name: "legacy"},
		{name: "split", split: true},
		{name: "split-excludes-oci", split: true, files: map[string]string{
			"config/jobs/oci/invalid.yaml": "presubmits: invalid-type\n",
		}},
		{name: "mixed-core", split: true, wantErr: true, files: map[string]string{
			"config/config.yaml": checkerFixtureConfig,
		}},
		{name: "mixed-plugins", split: true, wantErr: true, files: map[string]string{
			"config/plugins.yaml": checkerFixturePlugins,
		}},
		{name: "missing-split-plugins", split: true, wantErr: true, remove: "config/prow/aws/plugins.yaml"},
		{name: "missing-split-config", split: true, wantErr: true, remove: "config/prow/aws/config.yaml"},
		{name: "missing-split-jobs", split: true, wantErr: true, remove: "config/jobs/aws"},
		{name: "valid-legacy-directory-leftover", split: true, wantErr: true, files: map[string]string{
			"config/jobs/legacy/valid.yaml": checkerFixtureJobs,
		}},
		{name: "invalid-legacy-directory-leftover", split: true, wantErr: true, files: map[string]string{
			"config/jobs/legacy/invalid.yaml": "presubmits: invalid-type\n",
		}},
		{name: "root-yaml-leftover", split: true, wantErr: true, files: map[string]string{
			"config/jobs/legacy.yaml": checkerFixtureJobs,
		}},
		{name: "root-yml-leftover", split: true, wantErr: true, files: map[string]string{
			"config/jobs/legacy.yml": checkerFixtureJobs,
		}},
		{name: "hidden-directory-leftover", split: true, wantErr: true, files: map[string]string{
			"config/jobs/.legacy/valid.yaml": checkerFixtureJobs,
		}},
		{name: "hidden-yaml-leftover", split: true, wantErr: true, files: map[string]string{
			"config/jobs/.legacy.yaml": checkerFixtureJobs,
		}},
		{name: "metadata-allowed", split: true, files: map[string]string{
			"config/jobs/README.md": "Job catalog documentation.\n",
			"config/jobs/OWNERS":    "approvers: []\n",
		}},
	}
	for _, split := range []bool{false, true} {
		layout := "legacy"
		configPath, pluginsPath, jobsPath := "config/config.yaml", "config/plugins.yaml", "config/jobs/example/valid.yaml"
		if split {
			layout = "split"
			configPath, pluginsPath, jobsPath = "config/prow/aws/config.yaml", "config/prow/aws/plugins.yaml", "config/jobs/aws/example/valid.yaml"
		}
		for _, invalid := range []struct{ name, path, content string }{
			{"config", configPath, "tide:\n  queries: invalid-type\n"},
			{"plugins", pluginsPath, "plugins: invalid-type\n"},
			{"jobs", jobsPath, "presubmits: invalid-type\n"},
		} {
			cases = append(cases, layoutCase{name: layout + "-invalid-" + invalid.name, split: split,
				files: map[string]string{invalid.path: invalid.content}, wantErr: true})
		}
	}

	for _, jobName := range []string{"check-prow-config", "check-prow-config-periodic"} {
		t.Run(jobName, func(t *testing.T) {
			container := jobs[jobName]
			for _, tc := range cases {
				t.Run(tc.name, func(t *testing.T) {
					fixture := t.TempDir()
					// The mounted fixtures contain public synthetic config only.
					if err := os.Chmod(fixture, 0o755); err != nil {
						t.Fatal(err)
					}
					configPath, pluginsPath, jobsPath := "config/config.yaml", "config/plugins.yaml", "config/jobs/example/valid.yaml"
					if tc.split {
						configPath, pluginsPath, jobsPath = "config/prow/aws/config.yaml", "config/prow/aws/plugins.yaml", "config/jobs/aws/example/valid.yaml"
					}
					files := map[string]string{configPath: checkerFixtureConfig, pluginsPath: checkerFixturePlugins, jobsPath: checkerFixtureJobs}
					for path, content := range tc.files {
						files[path] = content
					}
					for path, content := range files {
						destination := filepath.Join(fixture, path)
						if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
							t.Fatal(err)
						}
						if err := os.WriteFile(destination, []byte(content), 0o644); err != nil {
							t.Fatal(err)
						}
					}
					if tc.remove != "" {
						if err := os.RemoveAll(filepath.Join(fixture, tc.remove)); err != nil {
							t.Fatal(err)
						}
					}
					ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
					defer cancel()
					args := []string{"run", "--rm", "--pull=never", "--network=none", "--read-only", "--cap-drop=ALL",
						"--security-opt=no-new-privileges", "--platform=linux/amd64",
						"--mount", "type=bind,src=" + fixture + ",dst=/workspace,readonly", "--workdir", "/workspace",
						"--entrypoint", container.Command[0], container.Image}
					// Prow decoration also concatenates Command and Args without shell splitting.
					args = append(args, container.Command[1:]...)
					args = append(args, container.Args...)
					output, err := exec.CommandContext(ctx, "docker", args...).CombinedOutput()
					if ctx.Err() != nil {
						t.Fatalf("Checker timed out: %v\n%s", ctx.Err(), output)
					}
					if tc.wantErr {
						var exitErr *exec.ExitError
						if !errors.As(err, &exitErr) || exitErr.ExitCode() != 1 {
							t.Fatalf("Expected validator or layout rejection (exit 1), got %v\n%s", err, output)
						}
					} else if err != nil {
						t.Fatalf("Expected valid layout: %v\n%s", err, output)
					}
				})
			}
		})
	}
}

func ensureCheckerImage(t *testing.T, image string) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()
	if err := exec.CommandContext(ctx, "docker", "image", "inspect", "--format", "{{.Id}}", image).Run(); err == nil {
		return
	}
	// CI starts without cached images. Only this preflight may contact a registry;
	// each subsequent checker execution has both --pull=never and --network=none.
	if output, err := exec.CommandContext(ctx, "docker", "pull", "--platform=linux/amd64", image).CombinedOutput(); err != nil {
		t.Fatalf("Load checker image %s: %v\n%s", image, err, output)
	}
}

const checkerFixtureConfig = "prowjob_namespace: prow\npod_namespace: test-pods\n"
const checkerFixturePlugins = "plugins: {}\n"
const checkerFixtureJobs = `presubmits:
  example/project:
  - name: fixture-job
    always_run: true
    decorate: false
    spec:
      containers:
      - name: test
        image: example.invalid/fixture
        command: ["/bin/true"]
`
