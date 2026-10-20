// SPDX-License-Identifier: Apache-2.0
package main

import (
	"bytes"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	prowconfig "sigs.k8s.io/prow/pkg/config"
	prowyaml "sigs.k8s.io/yaml"
)

func TestArchivalWaitsForGitHubBeforeCleanup(t *testing.T) {
	for _, inCatalog := range []bool{true, false} {
		p, s := fixture(t)
		if !inCatalog {
			p.Catalog = p.Catalog[:2]
		}
		repo := s.Repositories["archived"]
		repo.Archived = false
		s.Repositories["archived"] = repo
		before, err := yamlBytes(p.OrgDocument, "")
		if err != nil {
			t.Fatal(err)
		}
		pending, err := reconcile(p, s)
		if err != nil {
			t.Fatal(err)
		}
		if strings.Join(pending.PendingArchivals, ",") != "archived" || len(pending.Files) != 0 {
			t.Fatal("pending archive was not deferred")
		}
		after, err := yamlBytes(p.OrgDocument, "")
		if err != nil || !bytes.Equal(before, after) {
			t.Fatal("pending request was modified before Peribolos applied it")
		}
		if err := validateMetadata(p); err == nil {
			t.Fatal("pending archival accepted for downstream generation")
		}
		repo.Archived = true
		s.Repositories["archived"] = repo
		result, err := reconcile(p, s)
		if err != nil {
			t.Fatal(err)
		}
		if len(result.PendingArchivals) != 0 {
			t.Fatal("confirmed archival remains pending")
		}
		if strings.Contains(string(result.Files["config/org.yaml"]), "archived") ||
			strings.Contains(string(result.Files["config/org.yaml"]), "- obsolete") {
			t.Fatal("archived configuration or archived-only membership retained")
		}
		if _, err := applyResult(p.Dir, result, true); err != nil {
			t.Fatal(err)
		}
		accepted, err := loadProject(p.Dir)
		if err != nil {
			t.Fatal(err)
		}
		if err = validateMetadata(accepted); err != nil {
			t.Fatal(err)
		}
		next, err := reconcile(accepted, s)
		if err != nil {
			t.Fatal(err)
		}
		changed, err := applyResult(p.Dir, next, false)
		if err != nil || len(changed) != 0 {
			t.Fatalf("cleanup is not stable: %v, %v", changed, err)
		}
	}
}

func TestPendingArchivalDoesNotHideIncompleteInventory(t *testing.T) {
	for _, scenario := range []string{"missing-requested-repo", "unregistered-active-repo", "undeclared-retirement"} {
		t.Run(scenario, func(t *testing.T) {
			p, s := fixture(t)
			repo := s.Repositories["archived"]
			repo.Archived = false
			s.Repositories["archived"] = repo
			switch scenario {
			case "missing-requested-repo":
				delete(s.Repositories, "archived")
			case "unregistered-active-repo":
				s.Repositories["unknown"] = RepoSnapshot{Name: "unknown"}
			case "undeclared-retirement":
				p.Catalog = p.Catalog[:2]
				delete(p.Org.Repos, "archived")
			}
			if _, err := reconcile(p, s); err == nil {
				t.Fatal("incomplete or undeclared inventory accepted")
			}
		})
	}
}

func TestRetireOnlyMarkedMigrationCopy(t *testing.T) {
	dir := t.TempDir()
	if err := os.Mkdir(filepath.Join(dir, "config"), 0755); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(dir, "config/org.yaml")
	if removed, err := retireLegacyOrg(dir, true); err != nil || removed {
		t.Fatal("absent migration copy was not a no-op")
	}
	if err := os.WriteFile(path, []byte("orgs: {}\n"), 0644); err != nil {
		t.Fatal(err)
	}
	if _, err := retireLegacyOrg(dir, true); err == nil {
		t.Fatal("unmarked configuration was removed")
	}
	if err := os.WriteFile(path, []byte(legacyOrgMarker+"\norgs: {}\n"), 0644); err != nil {
		t.Fatal(err)
	}
	if changed, err := retireLegacyOrg(dir, false); err != nil || !changed {
		t.Fatal("dry run did not report cleanup")
	}
	if _, err := os.Stat(path); err != nil {
		t.Fatal("dry run removed the file")
	}
	if changed, err := retireLegacyOrg(dir, true); err != nil || !changed {
		t.Fatal("marked copy was not removed")
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatal("migration copy remains")
	}
}

func TestPeribolosActivationAppliesAcceptedArchival(t *testing.T) {
	b, err := os.ReadFile("../../config/jobs/oci/peribolos/peribolos.yaml")
	if err != nil {
		t.Fatal(err)
	}
	var jobs prowconfig.JobConfig
	if err = prowyaml.UnmarshalStrict(b, &jobs); err != nil {
		t.Fatal(err)
	}
	for _, repo := range []string{"falcosecurity/.project", "falcosecurity/test-infra"} {
		list := jobs.PostsubmitsStatic[repo]
		if len(list) != 1 {
			t.Fatalf("missing apply job for %s", repo)
		}
		job := list[0]
		if job.JobQueueName != "governance" || len(job.ExtraRefs) != 1 ||
			job.ExtraRefs[0].Repo != ".project" || job.ExtraRefs[0].BaseRef != "main" || !job.ExtraRefs[0].WorkDir {
			t.Fatalf("apply job does not use accepted .project metadata: %s", repo)
		}
		args := newSet(job.Spec.Containers[0].Args...)
		for _, flag := range []string{"--confirm", "--allow-repo-archival", "--fix-repos", "--config-path=config/org.yaml"} {
			if !args[flag] {
				t.Fatalf("%s missing %s", repo, flag)
			}
		}
		if repo == "falcosecurity/test-infra" {
			trigger := regexp.MustCompile(job.RunIfChanged)
			for _, path := range []string{"config/jobs/oci/peribolos/peribolos.yaml", "config/org.yaml"} {
				if !trigger.MatchString(path) {
					t.Fatalf("activation does not match %s", path)
				}
			}
		}
	}
	periodic := jobs.Periodics[0]
	if !newSet(periodic.Spec.Containers[0].Args...)["--allow-repo-archival"] {
		t.Fatal("periodic recovery cannot archive")
	}
}
