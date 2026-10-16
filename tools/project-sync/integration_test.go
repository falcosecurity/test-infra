// SPDX-License-Identifier: Apache-2.0
package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	prowconfig "sigs.k8s.io/prow/pkg/config"
	prowyaml "sigs.k8s.io/yaml"
)

func TestInvalidAccountsPolicy(t *testing.T) {
	for _, role := range []string{"approvers", "reviewers", "emeritus_approvers", "emeritus_reviewers"} {
		for _, kind := range []string{"missing", "organization"} {
			t.Run(role+"/"+kind, func(t *testing.T) {
				p, s := fixture(t)
				s.Repositories["engine"].Files["OWNERS"] = "approvers: [alice, admin]\nreviewers: [bob]\n"
				s.Repositories["engine"].Files["bad/OWNERS"] = role + ": [invalid]\n"
				s.Accounts = map[string]Account{}
				for _, login := range []string{"alice", "admin", "bob", "nested"} {
					s.Accounts[login] = Account{Login: login, ID: 1, Type: "User"}
				}
				if kind == "organization" {
					s.Accounts["invalid"] = Account{Login: "invalid", ID: 2, Type: "Organization"}
				} else {
					s.Accounts["invalid"] = Account{}
				}
				r, err := reconcile(p, s)
				if !strings.HasPrefix(role, "emeritus") {
					if err == nil || !strings.Contains(err.Error(), "active owner invalid") {
						t.Fatalf("invalid active owner not rejected: %v", err)
					}
				} else {
					if err != nil {
						t.Fatal(err)
					}
					if !strings.Contains(strings.Join(r.Summary, "\n"), "ignored invalid emeritus account invalid") {
						t.Fatal("missing warning")
					}
					if strings.Contains(string(r.Files["config/org.yaml"]), "- invalid") {
						t.Fatal("invalid member retained")
					}
				}
			})
		}
	}
}
func TestAccountRenameAndIncompleteVerification(t *testing.T) {
	o := Ownership{newSet("old"), newSet(), newSet(), newSet("old")}
	got, _, err := validateAccounts(o, map[string]Account{"old": {Login: "New", ID: 42, Type: "User"}})
	if err != nil || !got.Approvers["new"] || !got.RootApprovers["new"] {
		t.Fatalf("rename: %+v %v", got, err)
	}
	if _, _, err = validateAccounts(o, map[string]Account{}); err == nil {
		t.Fatal("missing verification accepted")
	}
}
func TestMalformedOwnersCannotRemoveRoles(t *testing.T) {
	for _, text := range []string{"filters:\n  '.*':\n    aprovers: [alice]\n", "filters: {}\nreviewers: [bob]\n", "filters: []\n", "approvers: alice\n"} {
		_, err := parseOwnership(RepoSnapshot{Name: "bad", Files: map[string]string{"OWNERS": text}})
		if err == nil {
			t.Errorf("accepted malformed OWNERS: %s", text)
		}
	}
}
func TestCatalogEditsAndScopeChanges(t *testing.T) {
	p, s := fixture(t)
	r, err := reconcile(p, s)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = applyResult(p.Dir, r, true); err != nil {
		t.Fatal(err)
	}
	p, err = loadProject(p.Dir)
	if err != nil {
		t.Fatal(err)
	}
	p.Catalog = append(p.Catalog, Repository{Name: "new-repo", Scope: "Core", Status: "Sandbox"})
	if err = validateEditable(p); err != nil {
		t.Fatalf("catalog edit blocked before reconciliation: %v", err)
	}
	s.Repositories["new-repo"] = RepoSnapshot{Name: "new-repo", DefaultBranch: "main", Files: map[string]string{"OWNERS": "approvers: [newperson]\n"}}
	r, err = reconcile(p, s)
	if err != nil {
		t.Fatal(err)
	}
	if !r.Core["newperson"] {
		t.Fatal("new Core repository did not grant core status")
	}
	p.Catalog[len(p.Catalog)-1].Scope = "Ecosystem"
	r, err = reconcile(p, s)
	if err != nil {
		t.Fatal(err)
	}
	if r.Core["newperson"] {
		t.Fatal("scope demotion retained core status")
	}
}
func TestGeneratedJobsUseTrustedCodeAndAllTriggers(t *testing.T) {
	p, s := fixture(t)
	p.Catalog = append(p.Catalog, Repository{Name: ".project", Scope: "Special"})
	s.Repositories[".project"] = RepoSnapshot{Name: ".project", DefaultBranch: "main", Files: map[string]string{"OWNERS": "approvers: [alice]\n"}}
	r, err := reconcile(p, s)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = applyResult(p.Dir, r, true); err != nil {
		t.Fatal(err)
	}
	p, err = loadProject(p.Dir)
	if err != nil {
		t.Fatal(err)
	}
	r, err = renderJobs(p)
	if err != nil {
		t.Fatal(err)
	}
	var jobs prowconfig.JobConfig
	if err = prowyaml.UnmarshalStrict(r.Files[jobsPath], &jobs); err != nil {
		t.Fatalf("Prow schema: %v", err)
	}
	if len(jobs.Periodics) != 1 || len(jobs.PostsubmitsStatic) != 3 {
		t.Fatalf("incorrect catalog: %+v", jobs)
	}
	for repo, list := range jobs.PostsubmitsStatic {
		if len(list) != 1 {
			t.Fatal(repo)
		}
		job := list[0]
		if job.JobQueueName != "governance" || len(job.ExtraRefs) != 1 || job.ExtraRefs[0].Repo != "test-infra" || job.ExtraRefs[0].BaseRef != "master" || !job.ExtraRefs[0].WorkDir {
			t.Fatalf("untrusted job: %+v", job)
		}
		if !strings.Contains(job.RunIfChanged, "OWNERS") {
			t.Fatal("missing ownership trigger")
		}
		if repo == "falcosecurity/.project" && !strings.Contains(job.RunIfChanged, "affiliations") {
			t.Fatal("missing metadata trigger")
		}
	}
}
func fakeGitHub(t *testing.T, fn http.HandlerFunc) *GitHub {
	t.Helper()
	server := httptest.NewServer(fn)
	t.Cleanup(server.Close)
	return &GitHub{Token: "test-token", BaseURL: server.URL, HTTP: server.Client()}
}
func TestSnapshotRejectsIncompleteTreeAndAccountFailure(t *testing.T) {
	for _, scenario := range []string{"ok", "truncated", "account-failure", "missing-account"} {
		t.Run(scenario, func(t *testing.T) {
			g := fakeGitHub(t, func(w http.ResponseWriter, r *http.Request) {
				if r.Header.Get("Authorization") != "Bearer test-token" {
					t.Error("missing authentication")
				}
				switch {
				case strings.HasPrefix(r.URL.Path, "/orgs/"):
					fmt.Fprint(w, `[{"name":"engine","default_branch":"main"},{"name":"archived","archived":true,"default_branch":"main"}]`)
				case strings.Contains(r.URL.Path, "/git/ref/"):
					fmt.Fprint(w, `{"object":{"sha":"abc"}}`)
				case strings.Contains(r.URL.Path, "/git/trees/"):
					fmt.Fprintf(w, `{"truncated":%t,"tree":[{"path":"OWNERS","type":"blob","sha":"blob"}]}`, scenario == "truncated")
				case strings.Contains(r.URL.Path, "/git/blobs/"):
					json.NewEncoder(w).Encode(map[string]any{"encoding": "base64", "size": 19, "content": base64.StdEncoding.EncodeToString([]byte("approvers: [alice]\n"))})
				case r.URL.Path == "/users/alice":
					if scenario == "account-failure" {
						w.WriteHeader(503)
						return
					}
					if scenario == "missing-account" {
						w.WriteHeader(404)
						return
					}
					fmt.Fprint(w, `{"login":"alice","id":1,"type":"User"}`)
				default:
					t.Errorf("unexpected path %s", r.URL)
					w.WriteHeader(500)
				}
			})
			snapshot, err := g.snapshot(context.Background())
			if scenario == "truncated" || scenario == "account-failure" {
				if err == nil {
					t.Fatal("partial snapshot accepted")
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if snapshot.Accounts == nil || len(snapshot.Repositories) != 2 {
				t.Fatal("snapshot lost account results or repositories")
			}
			if scenario == "ok" && snapshot.Accounts["alice"].ID != 1 {
				t.Fatal("verification missing")
			}
			if scenario == "missing-account" && snapshot.Accounts["alice"].ID != 0 {
				t.Fatal("missing account became valid")
			}
		})
	}
}
func TestBotPRRejectsHumanContributions(t *testing.T) {
	for _, scenario := range []string{"bot", "human-author", "human-commit", "unknown-commit", "none"} {
		t.Run(scenario, func(t *testing.T) {
			g := fakeGitHub(t, func(w http.ResponseWriter, r *http.Request) {
				if strings.HasSuffix(r.URL.Path, "/commits") {
					switch scenario {
					case "human-commit":
						fmt.Fprint(w, `[{"author":{"login":"alice"}}]`)
					case "unknown-commit":
						fmt.Fprint(w, `[{"author":null}]`)
					default:
						fmt.Fprint(w, `[{"author":{"login":"poiana"}}]`)
					}
				} else {
					switch scenario {
					case "none":
						fmt.Fprint(w, `[]`)
					case "human-author":
						fmt.Fprint(w, `[{"number":1,"user":{"login":"alice"}}]`)
					default:
						fmt.Fprint(w, `[{"number":1,"user":{"login":"poiana"},"head":{"sha":"abc"}}]`)
					}
				}
			})
			p, err := g.botPull(context.Background(), "engine", "project-sync/metadata")
			if scenario == "bot" {
				if err != nil || p == nil {
					t.Fatalf("bot rejected: %v", err)
				}
			} else if scenario == "none" {
				if err != nil || p != nil {
					t.Fatal("nonexistent PR")
				}
			} else if err == nil {
				t.Fatal("human content accepted")
			}
		})
	}
}

func TestUnchangedBotProposalDoesNotCommitOrPublish(t *testing.T) {
	ctx := context.Background()
	dir := t.TempDir()
	env := []string{"GIT_CONFIG_COUNT=3", "GIT_CONFIG_KEY_0=user.name", "GIT_CONFIG_VALUE_0=Test", "GIT_CONFIG_KEY_1=user.email", "GIT_CONFIG_VALUE_1=test@example.invalid", "GIT_CONFIG_KEY_2=commit.gpgsign", "GIT_CONFIG_VALUE_2=false"}
	for _, args := range [][]string{{"init", "--initial-branch=main"}, {"commit", "--allow-empty", "-m", "base"}} {
		if _, err := git(ctx, dir, env, args...); err != nil {
			t.Fatal(err)
		}
	}
	base, err := git(ctx, dir, nil, "rev-parse", "HEAD")
	if err != nil {
		t.Fatal(err)
	}
	if _, err = writeChanged(dir+"/metadata.yaml", []byte("generated: true\n"), true); err != nil {
		t.Fatal(err)
	}
	if _, err = git(ctx, dir, nil, "add", "metadata.yaml"); err != nil {
		t.Fatal(err)
	}
	tree, err := git(ctx, dir, nil, "write-tree")
	if err != nil {
		t.Fatal(err)
	}
	g := fakeGitHub(t, func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "GET" {
			t.Errorf("unchanged proposal performed %s", r.Method)
			w.WriteHeader(500)
			return
		}
		switch {
		case strings.HasSuffix(r.URL.Path, "/pulls"):
			fmt.Fprint(w, `[{"number":1,"user":{"login":"poiana"},"head":{"sha":"bot-head"}}]`)
		case strings.HasSuffix(r.URL.Path, "/pulls/1/commits"):
			fmt.Fprint(w, `[{"author":{"login":"poiana"}}]`)
		case strings.Contains(r.URL.Path, "/git/ref/"):
			fmt.Fprintf(w, `{"object":{"sha":%q}}`, base)
		case strings.HasSuffix(r.URL.Path, "/git/commits/bot-head"):
			fmt.Fprintf(w, `{"tree":{"sha":%q}}`, tree)
		default:
			t.Errorf("unexpected request: %s", r.URL.Path)
			w.WriteHeader(500)
		}
	})
	if err = g.publish(ctx, dir, "engine", "main", "project-sync/metadata", "title", "body", []string{"metadata.yaml"}, nil); err != nil {
		t.Fatal(err)
	}
	after, err := git(ctx, dir, nil, "rev-parse", "HEAD")
	if err != nil || after != base {
		t.Fatal("unchanged proposal committed again")
	}
	if err = checkCheckout(ctx, dir, RepoSnapshot{Name: "engine", SHA: "stale"}); err == nil {
		t.Fatal("stale source accepted")
	}
}
func TestPurposeTeamWithMaintainersSuffixSurvives(t *testing.T) {
	p, s := fixture(t)
	teams := field(field(field(p.OrgDocument, "orgs"), organization), "teams")
	team := ensureMap(teams, "security-maintainers")
	p.Org.Teams["security-maintainers"] = p.Org.Teams["special-maintainers"]
	if err := put(team, "members", []string{"alice"}); err != nil {
		t.Fatal(err)
	}
	if err := put(team, "repos", map[string]string{"engine": "triage"}); err != nil {
		t.Fatal(err)
	}
	r, err := reconcile(p, s)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(r.Files["config/org.yaml"]), "security-maintainers:") {
		t.Fatal("manually managed team removed")
	}
}
