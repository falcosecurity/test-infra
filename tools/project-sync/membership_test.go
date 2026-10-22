// SPDX-License-Identifier: Apache-2.0
package main

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"testing"

	proworg "sigs.k8s.io/prow/pkg/config/org"
	prowyaml "sigs.k8s.io/yaml"
)

func TestEmeritusRetentionDoesNotInvite(t *testing.T) {
	for _, scenario := range []string{"existing", "absent", "requested-departure", "former-reviewer", "active-reviewer", "missing-snapshot"} {
		t.Run(scenario, func(t *testing.T) {
			p, s := fixture(t)
			switch scenario {
			case "absent", "active-reviewer":
				delete(s.Members, "retired")
				if scenario == "active-reviewer" {
					s.Repositories["engine"].Files["other/OWNERS"] = "reviewers: [retired]\n"
				}
			case "requested-departure":
				p.Org.Members = newSet(p.Org.Members...).minus(newSet("retired")).list()
			case "former-reviewer":
				s.Repositories["engine"].Files["OWNERS"] = "approvers: [alice, admin]\nreviewers: [bob]\nemeritus_reviewers: [retired]\n"
			case "missing-snapshot":
				s.Members = nil
			}
			r, err := reconcile(p, s)
			if scenario == "missing-snapshot" {
				if err == nil {
					t.Fatal("unverified membership accepted")
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			var cfg proworg.FullConfig
			if err = prowyaml.UnmarshalStrict(r.Files["config/org.yaml"], &cfg); err != nil {
				t.Fatal(err)
			}
			want := scenario == "existing" || scenario == "active-reviewer"
			if newSet(cfg.Orgs[organization].Members...)["retired"] != want {
				t.Fatalf("retained emeritus membership: want %t", want)
			}
		})
	}
}

func TestVerifiedHistoricalAliases(t *testing.T) {
	for _, scenario := range []string{"existing", "absent", "wrong-id", "active-old-handle", "no-id", "duplicate", "alias-is-profile"} {
		t.Run(scenario, func(t *testing.T) {
			p, s := fixture(t)
			p.Affiliations["retired"] = Person{Name: "Former Maintainer", GitHubID: s.Members["retired"].ID, EmeritusAliases: []string{"historical"}}
			s.Repositories["engine"].Files["OWNERS"] = "approvers: [alice, admin]\nreviewers: [bob]\nemeritus_approvers: [historical]\n"
			s.Accounts = map[string]Account{}
			for _, login := range []string{"alice", "admin", "bob", "nested", "retired"} {
				s.Accounts[login] = Account{Login: login, ID: 1, Type: "User"}
			}
			// The old handle is now used by an unrelated organization.
			s.Accounts["historical"] = Account{Login: "historical", ID: 999, Type: "Organization"}
			switch scenario {
			case "absent":
				delete(s.Members, "retired")
			case "wrong-id":
				s.Members["retired"] = Account{Login: "retired", ID: 999, Type: "User"}
			case "active-old-handle":
				s.Repositories["engine"].Files["other/OWNERS"] = "approvers: [historical]\n"
			case "no-id":
				person := p.Affiliations["retired"]
				person.GitHubID = 0
				p.Affiliations["retired"] = person
			case "duplicate":
				p.Affiliations["another"] = Person{GitHubID: 99, EmeritusAliases: []string{"Historical"}}
			case "alias-is-profile":
				p.Affiliations["historical"] = Person{}
			}
			r, err := reconcile(p, s)
			if scenario != "existing" && scenario != "absent" {
				if err == nil {
					t.Fatal("invalid historical identity accepted")
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			var cfg proworg.FullConfig
			if err = prowyaml.UnmarshalStrict(r.Files["config/org.yaml"], &cfg); err != nil {
				t.Fatal(err)
			}
			members := newSet(cfg.Orgs[organization].Members...)
			if members["historical"] || members["retired"] != (scenario == "existing") {
				t.Fatal("historical identity did not preserve membership correctly")
			}
			if !strings.Contains(string(r.Files["config/affiliations.yaml"]), "emeritus_aliases:") {
				t.Fatal("verified history was lost")
			}
		})
	}
}

func TestMembershipScanRequiresFullVisibility(t *testing.T) {
	for _, scenario := range []string{"ok", "pending", "denied", "second-page-failure", "invalid-account"} {
		t.Run(scenario, func(t *testing.T) {
			g := fakeGitHub(t, func(w http.ResponseWriter, r *http.Request) {
				switch r.URL.Path {
				case "/user/memberships/orgs/falcosecurity":
					switch scenario {
					case "pending":
						fmt.Fprint(w, `{"state":"pending"}`)
					case "denied":
						w.WriteHeader(http.StatusForbidden)
					default:
						fmt.Fprint(w, `{"state":"active"}`)
					}
				case "/orgs/falcosecurity/members":
					if r.URL.Query().Get("page") == "2" {
						if scenario == "second-page-failure" {
							w.WriteHeader(http.StatusServiceUnavailable)
						} else {
							fmt.Fprint(w, `[{"login":"last","id":101,"type":"User"}]`)
						}
						return
					}
					if scenario == "invalid-account" {
						fmt.Fprint(w, `[{"login":"invalid","id":1,"type":"Organization"}]`)
						return
					}
					fmt.Fprint(w, "[")
					for i := 1; i <= 100; i++ {
						if i > 1 {
							fmt.Fprint(w, ",")
						}
						fmt.Fprintf(w, `{"login":"user%d","id":%d,"type":"User"}`, i, i)
					}
					fmt.Fprint(w, "]")
				default:
					t.Errorf("unexpected endpoint %s", r.URL)
					w.WriteHeader(500)
				}
			})
			members, err := g.members(context.Background())
			if scenario != "ok" {
				if err == nil {
					t.Fatal("partial membership accepted")
				}
				return
			}
			if err != nil || len(members) != 101 {
				t.Fatalf("pagination failed: %d members, %v", len(members), err)
			}
			members["last"] = Account{Login: "last", ID: 999, Type: "User"}
			if err := g.verifySnapshot(context.Background(), Snapshot{Members: members}); err == nil || !strings.Contains(err.Error(), "membership changed") {
				t.Fatalf("membership race accepted: %v", err)
			}
		})
	}
}
