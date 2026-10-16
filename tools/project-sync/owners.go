// SPDX-License-Identifier: Apache-2.0
package main

import (
	"fmt"
	"path"
	"regexp"
	"strings"

	"gopkg.in/yaml.v3"
	"sigs.k8s.io/prow/pkg/repoowners"
)

var loginPattern = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9-]{0,38}$`)
var repoPattern = regexp.MustCompile(`^[a-zA-Z0-9_.-]{1,100}$`)

// Prow intentionally ignores emeritus fields for review authorization. Read only
// these additional fields ourselves; use Prow's public parsers for active roles.
type emeritusConfig struct {
	Approvers []string                  `yaml:"emeritus_approvers"`
	Reviewers []string                  `yaml:"emeritus_reviewers"`
	Filters   map[string]emeritusConfig `yaml:"filters"`
}

func parseOwnership(repo RepoSnapshot) (Ownership, error) {
	o := Ownership{set{}, set{}, set{}, set{}}
	if _, ok := repo.Files["OWNERS"]; !ok {
		return o, fmt.Errorf("%s has no root OWNERS; refusing partial reconciliation", repo.Name)
	}
	aliases := repoowners.RepoAliases{}
	if b, ok := repo.Files["OWNERS_ALIASES"]; ok {
		var err error
		aliases, err = repoowners.ParseAliasesConfig([]byte(b))
		if err != nil {
			return o, fmt.Errorf("%s aliases: %w", repo.Name, err)
		}
	}
	expand := func(values []string) (set, error) {
		s := set{}
		for _, v := range values {
			v = strings.ToLower(strings.TrimSpace(v))
			if a, ok := aliases[v]; ok {
				for _, member := range a.UnsortedList() {
					if !loginPattern.MatchString(member) {
						return nil, fmt.Errorf("invalid alias member %q", member)
					}
					s.add(member)
				}
			} else {
				if !loginPattern.MatchString(v) {
					return nil, fmt.Errorf("invalid GitHub login %q", v)
				}
				s.add(v)
			}
		}
		return s, nil
	}
	for name, text := range repo.Files {
		if path.Base(name) != "OWNERS" {
			continue
		}
		var node yaml.Node
		if err := yaml.Unmarshal([]byte(text), &node); err != nil {
			return o, fmt.Errorf("%s/%s: %w", repo.Name, name, err)
		}
		// Empty/comment-only nested OWNERS files inherit parent ownership in Prow.
		if len(node.Content) == 0 {
			continue
		}
		if node.Content[0].Kind != yaml.MappingNode {
			return o, fmt.Errorf("%s/%s must be a mapping", repo.Name, name)
		}
		// Detect duplicates and misspelled fields before Prow's permissive parser.
		var duplicateCheck map[string]any
		if err := node.Decode(&duplicateCheck); err != nil {
			return o, err
		}
		if err := validateOwnersKeys(duplicateCheck, true); err != nil {
			return o, fmt.Errorf("%s/%s: %w", repo.Name, name, err)
		}
		var configs []repoowners.Config
		if _, ok := duplicateCheck["filters"]; ok {
			f, err := repoowners.LoadFullConfig([]byte(text))
			if err != nil {
				return o, err
			}
			for pattern, c := range f.Filters {
				if _, err = regexp.Compile(pattern); err != nil {
					return o, err
				}
				configs = append(configs, c)
			}
		} else {
			c, err := repoowners.LoadSimpleConfig([]byte(text))
			if err != nil {
				return o, err
			}
			configs = append(configs, c.Config)
		}
		for _, c := range configs {
			a, err := expand(c.Approvers)
			if err != nil {
				return o, err
			}
			r, err := expand(c.Reviewers)
			if err != nil {
				return o, err
			}
			o.Approvers.union(a)
			o.Reviewers.union(r)
			if name == "OWNERS" {
				o.RootApprovers.union(a)
			}
		}
		var e emeritusConfig
		if err := yaml.Unmarshal([]byte(text), &e); err != nil {
			return o, err
		}
		all := append(e.Approvers, e.Reviewers...)
		for _, f := range e.Filters {
			all = append(all, f.Approvers...)
			all = append(all, f.Reviewers...)
		}
		em, err := expand(all)
		if err != nil {
			return o, err
		}
		o.Emeritus.union(em)
	}
	return o, nil
}

func validateOwnersKeys(m map[string]any, root bool) error {
	for key, value := range m {
		switch key {
		case "approvers", "reviewers", "required_reviewers", "emeritus_approvers", "emeritus_reviewers", "labels":
			if _, filtered := m["filters"]; filtered {
				return fmt.Errorf("mixed simple and filtered OWNERS")
			}
		case "options":
		case "filters":
			if !root {
				return fmt.Errorf("nested filters are unsupported")
			}
			filters, ok := value.(map[string]any)
			if !ok {
				return fmt.Errorf("filters must be a mapping")
			}
			for _, v := range filters {
				fields, ok := v.(map[string]any)
				if !ok {
					return fmt.Errorf("filter must be a mapping")
				}
				if err := validateOwnersKeys(fields, false); err != nil {
					return err
				}
			}
		default:
			return fmt.Errorf("unknown OWNERS field %q", key)
		}
	}
	return nil
}

func specialOwners(text string, core set) ([]byte, error) {
	var n yaml.Node
	if err := yaml.Unmarshal([]byte(text), &n); err != nil {
		return nil, err
	}
	if len(n.Content) != 1 || n.Content[0].Kind != yaml.MappingNode {
		return nil, fmt.Errorf("Special root OWNERS must be a mapping")
	}
	root := n.Content[0]
	if field(root, "filters") != nil {
		return nil, fmt.Errorf("Special root OWNERS uses filters; explicit migration required")
	}
	if err := put(root, "approvers", core.list()); err != nil {
		return nil, err
	}
	field(root, "approvers").HeadComment = "AUTOGENERATED - DO NOT EDIT this list.\nSource: .project/maintainers.yaml core-maintainers; reconciled by test-infra/tools/project-sync."
	for _, key := range []string{"reviewers", "emeritus_approvers", "emeritus_reviewers"} {
		if v := field(root, key); v != nil {
			var members []string
			if err := v.Decode(&members); err != nil {
				return nil, err
			}
			if err := put(root, key, newSet(members...).minus(core).list()); err != nil {
				return nil, err
			}
		}
	}
	return yamlBytes(&n, "")
}
