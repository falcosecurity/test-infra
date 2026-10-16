// SPDX-License-Identifier: Apache-2.0
package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
	proworg "sigs.k8s.io/prow/pkg/config/org"
	prowyaml "sigs.k8s.io/yaml"
)

func fixture(t *testing.T) (*Project, Snapshot) {
	t.Helper()
	text := `orgs:
  falcosecurity:
    admins: [admin]
    members: [alice, bob, retired, obsolete]
    repos:
      engine:
        description: Keep this manual description
        default_branch: main
        allow_merge_commit: false
      special:
        description: Special repo
        default_branch: main
      archived:
        archived: true
    teams:
      core-maintainers:
        members: [alice]
        maintainers: []
      core-maintainers-extra:
        members: []
      special-maintainers:
        members: [alice]
        maintainers: []
        repos: {special: maintain}
      archived-maintainers:
        members: [obsolete]
        repos: {archived: maintain}
      machine_users:
        maintainers: [admin]
        repos: {engine: admin, archived: admin}
`
	var doc yaml.Node
	if err := yaml.Unmarshal([]byte(text), &doc); err != nil {
		t.Fatal(err)
	}
	var cfg proworg.FullConfig
	if err := prowyaml.UnmarshalStrict([]byte(text), &cfg); err != nil {
		t.Fatal(err)
	}
	p := &Project{Dir: t.TempDir(), OrgDocument: &doc, Org: cfg.Orgs[organization], Catalog: []Repository{{Name: "engine", Scope: "Core", Status: "Stable"}, {Name: "special", Scope: "Special"}, {Name: "archived", Scope: "Infra", Status: "Deprecated"}}, Affiliations: map[string]Person{"alice": {Name: "Alice", Company: "Example"}, "obsolete": {Name: "Obsolete", Company: "Old"}}}
	s := Snapshot{Repositories: map[string]RepoSnapshot{
		"engine":   {Name: "engine", DefaultBranch: "main", SHA: "core-sha", Files: map[string]string{"OWNERS": "approvers: [Alice, admin]\nreviewers: [bob]\nemeritus_approvers: [retired]\n", "sub/OWNERS": "approvers: [nested]\nreviewers: [bob]\n", "empty/OWNERS": "# inherit parent\n"}},
		"special":  {Name: "special", DefaultBranch: "main", SHA: "special-sha", Files: map[string]string{"OWNERS": "approvers: [alice]\n"}},
		"archived": {Name: "archived", Archived: true, Files: map[string]string{"OWNERS": "approvers: [obsolete]\n"}},
	}}
	return p, s
}
func TestReconcileMembershipAndIdempotence(t *testing.T) {
	p, s := fixture(t)
	r, err := reconcile(p, s)
	if err != nil {
		t.Fatal(err)
	}
	var cfg proworg.FullConfig
	if err = prowyaml.UnmarshalStrict(r.Files["config/org.yaml"], &cfg); err != nil {
		t.Fatal(err)
	}
	o := cfg.Orgs[organization]
	if got := strings.Join(o.Members, ","); got != "alice,bob,nested,retired" {
		t.Fatalf("members = %s", got)
	}
	if got := strings.Join(r.Core.list(), ","); got != "admin,alice" {
		t.Fatalf("core = %s", got)
	}
	if *o.Repos["engine"].Description != "Keep this manual description" {
		t.Fatal("manual description changed")
	}
	if _, ok := o.Repos["archived"]; ok {
		t.Fatal("archived repo retained")
	}
	if _, ok := o.Teams["archived-maintainers"]; ok {
		t.Fatal("archived team retained")
	}
	if _, ok := o.Teams["machine_users"].Repos["archived"]; ok {
		t.Fatal("archived permission retained")
	}
	if strings.Join(o.Admins, ",") != "admin" {
		t.Fatal("admin list changed")
	}
	if _, err = applyResult(p.Dir, r, true); err != nil {
		t.Fatal(err)
	}
	loaded, err := loadProject(p.Dir)
	if err != nil {
		t.Fatal(err)
	}
	r2, err := reconcile(loaded, s)
	if err != nil {
		t.Fatal(err)
	}
	for name, b := range r.Files {
		if !bytes.Equal(b, r2.Files[name]) {
			t.Errorf("second run changed %s\nfirst:\n%s\nsecond:\n%s", name, b, r2.Files[name])
		}
	}
}
func TestLastCoreRoleAndEmeritus(t *testing.T) {
	p, s := fixture(t)
	r := s.Repositories["engine"]
	r.Files["OWNERS"] = "approvers: [admin]\nreviewers: [bob]\nemeritus_approvers: [alice, retired]\n"
	s.Repositories["engine"] = r
	result, err := reconcile(p, s)
	if err != nil {
		t.Fatal(err)
	}
	if result.Core["alice"] {
		t.Fatal("Special ownership or emeritus retained core status")
	}
	var cfg proworg.FullConfig
	if err = prowyaml.UnmarshalStrict(result.Files["config/org.yaml"], &cfg); err != nil {
		t.Fatal(err)
	}
	if !newSet(cfg.Orgs[organization].Members...)["alice"] {
		t.Fatal("emeritus lost org membership")
	}
}
func TestIncompleteSnapshotCannotRemoveMembers(t *testing.T) {
	p, s := fixture(t)
	delete(s.Repositories, "engine")
	if _, err := reconcile(p, s); err == nil {
		t.Fatal("missing repository accepted")
	}
	p, s = fixture(t)
	r := s.Repositories["engine"]
	delete(r.Files, "OWNERS")
	s.Repositories["engine"] = r
	if _, err := reconcile(p, s); err == nil {
		t.Fatal("missing root OWNERS accepted")
	}
}
func TestManualTeamCannotBypassEligibility(t *testing.T) {
	p, s := fixture(t)
	teams := field(field(field(p.OrgDocument, "orgs"), organization), "teams")
	if err := put(ensureMap(teams, "manual-team"), "members", []string{"outsider"}); err != nil {
		t.Fatal(err)
	}
	if _, err := reconcile(p, s); err == nil || !strings.Contains(err.Error(), "outsider") {
		t.Fatalf("expected manual team conflict: %v", err)
	}
}
func TestAliasesAndFilteredOwners(t *testing.T) {
	r := RepoSnapshot{Name: "sample", Files: map[string]string{
		"OWNERS_ALIASES": "aliases:\n  owners: [Alice, bob]\n",
		"OWNERS":         "approvers: [owners]\nemeritus_approvers: [retired]\n",
		"sub/OWNERS":     "filters:\n  '.*':\n    approvers: [nested]\n    reviewers: [reader]\n    emeritus_reviewers: [former]\n",
	}}
	o, err := parseOwnership(r)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Join(o.Approvers.list(), ",") != "alice,bob,nested" || strings.Join(o.RootApprovers.list(), ",") != "alice,bob" {
		t.Fatalf("bad approvers: %+v", o)
	}
	if !o.Emeritus["former"] || !o.Emeritus["retired"] || !o.Reviewers["reader"] {
		t.Fatal("lost roles")
	}
	r.Files["OWNERS"] = "approvers: [alice]\napprovers: [bob]\n"
	if _, err = parseOwnership(r); err == nil {
		t.Fatal("duplicate fields accepted")
	}
}
func TestSpecialOwnersPreservesHistoryAndSettings(t *testing.T) {
	b, err := specialOwners("# human comment\napprovers: [old]\nreviewers: [new, specialist]\nemeritus_approvers: [new, historical]\nlabels: [area/docs]\n", newSet("new"))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"human comment", "historical", "specialist", "area/docs", "AUTOGENERATED"} {
		if !strings.Contains(string(b), want) {
			t.Errorf("missing %s", want)
		}
	}
	var n map[string]any
	if err = yaml.Unmarshal(b, &n); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(b), "- old") {
		t.Fatal("removed core maintainer retained")
	}
	b2, err := specialOwners(string(b), newSet("new"))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(b, b2) {
		t.Fatal("Special OWNERS not idempotent")
	}
}
func TestRenderingFollowsAffiliationsAndCatalog(t *testing.T) {
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
	dir := t.TempDir()
	md := "Human prose.\n\n<!-- MAINTAINERS-CORE-LIST -->\n<!-- /MAINTAINERS-CORE-LIST -->\n<!-- MAINTAINERS-LIST -->\n<!-- /MAINTAINERS-LIST -->\n"
	readme := "Introduction stays.\n"
	for _, scope := range []string{"CORE", "ECOSYSTEM", "INFRA", "SPECIAL"} {
		readme += "<!-- REPOSITORY-" + scope + "-TABLE -->\n<!-- /REPOSITORY-" + scope + "-TABLE -->\n"
	}
	if err = os.WriteFile(filepath.Join(dir, "MAINTAINERS.md"), []byte(md), 0644); err != nil {
		t.Fatal(err)
	}
	if err = os.WriteFile(filepath.Join(dir, "README.md"), []byte(readme), 0644); err != nil {
		t.Fatal(err)
	}
	if _, err = render(p, dir, true); err != nil {
		t.Fatal(err)
	}
	changed, err := render(p, dir, false)
	if err != nil {
		t.Fatal(err)
	}
	if len(changed) != 0 {
		t.Fatalf("repeat render changed %v", changed)
	}
	p.Affiliations["alice"] = Person{Name: "Alice", Company: "New company"}
	changed, err = render(p, dir, true)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Join(changed, ",") != "MAINTAINERS.md" {
		t.Fatalf("affiliation changed %v", changed)
	}
	b, _ := os.ReadFile(filepath.Join(dir, "MAINTAINERS.md"))
	if !strings.Contains(string(b), "Human prose.") || !strings.Contains(string(b), "New company") {
		t.Fatal("bad rendering")
	}
}
