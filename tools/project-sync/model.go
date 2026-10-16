// SPDX-License-Identifier: Apache-2.0
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
	proworg "sigs.k8s.io/prow/pkg/config/org"
	prowyaml "sigs.k8s.io/yaml"
)

const organization = "falcosecurity"

type Repository struct {
	Name   string `yaml:"name" json:"name"`
	Scope  string `yaml:"scope" json:"scope"`
	Status string `yaml:"status,omitempty" json:"status,omitempty"`
}
type Person struct {
	Name    string `yaml:"name" json:"name"`
	Company string `yaml:"company" json:"company"`
}
type Team struct {
	Name    string   `yaml:"name" json:"name"`
	Managed bool     `yaml:"managed" json:"managed"`
	Members []string `yaml:"members" json:"members"`
}
type Maintainers struct {
	Entries []MaintainerEntry `yaml:"maintainers" json:"maintainers"`
}
type MaintainerEntry struct {
	ProjectID string `yaml:"project_id" json:"project_id"`
	Org       string `yaml:"org" json:"org"`
	Teams     []Team `yaml:"teams" json:"teams"`
}
type RepoSnapshot struct {
	Name          string            `json:"name"`
	DefaultBranch string            `json:"default_branch"`
	SHA           string            `json:"sha"`
	Archived      bool              `json:"archived"`
	Files         map[string]string `json:"files,omitempty"`
}
type Snapshot struct {
	Repositories map[string]RepoSnapshot `json:"repositories"`
	Accounts     map[string]Account      `json:"accounts,omitempty"`
}
type Account struct {
	Login string `json:"login"`
	ID    int64  `json:"id"`
	Type  string `json:"type"`
}
type Ownership struct {
	Approvers     set
	Reviewers     set
	Emeritus      set
	RootApprovers set
}
type set map[string]bool

func newSet(values ...string) set { s := set{}; s.add(values...); return s }
func (s set) add(values ...string) {
	for _, v := range values {
		s[strings.ToLower(strings.TrimSpace(v))] = true
	}
}
func (s set) union(other set) {
	for v := range other {
		s[v] = true
	}
}
func (s set) list() []string {
	a := make([]string, 0, len(s))
	for v := range s {
		a = append(a, v)
	}
	sort.Strings(a)
	return a
}
func (s set) minus(other set) set {
	r := set{}
	for v := range s {
		if !other[v] {
			r[v] = true
		}
	}
	return r
}
func teamName(repo string) string { return strings.TrimPrefix(repo, ".") + "-maintainers" }

type Project struct {
	Dir          string
	Catalog      []Repository
	Affiliations map[string]Person
	OrgDocument  *yaml.Node
	Org          proworg.Config
	Maintainers  Maintainers
}

func loadYAML(path string, out any) error {
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	d := yaml.NewDecoder(bytes.NewReader(b))
	d.KnownFields(true)
	if err = d.Decode(out); err != nil {
		return fmt.Errorf("%s: %w", path, err)
	}
	return nil
}
func loadProject(dir string) (*Project, error) {
	p := &Project{Dir: dir}
	if err := loadYAML(filepath.Join(dir, "config/repository.yaml"), &p.Catalog); err != nil {
		return nil, err
	}
	if err := loadYAML(filepath.Join(dir, "config/affiliations.yaml"), &p.Affiliations); err != nil {
		return nil, err
	}
	b, err := os.ReadFile(filepath.Join(dir, "config/org.yaml"))
	if err != nil {
		return nil, err
	}
	p.OrgDocument = &yaml.Node{}
	if err = yaml.Unmarshal(b, p.OrgDocument); err != nil {
		return nil, err
	}
	var cfg proworg.FullConfig
	if err = prowyaml.UnmarshalStrict(b, &cfg); err != nil {
		return nil, fmt.Errorf("Peribolos config: %w", err)
	}
	var ok bool
	p.Org, ok = cfg.Orgs[organization]
	if !ok || len(cfg.Orgs) != 1 {
		return nil, fmt.Errorf("expected only org %s", organization)
	}
	if err = loadYAML(filepath.Join(dir, "maintainers.yaml"), &p.Maintainers); err != nil {
		return nil, err
	}
	return p, nil
}

func field(n *yaml.Node, key string) *yaml.Node {
	if n.Kind == yaml.DocumentNode {
		return field(n.Content[0], key)
	}
	for i := 0; i+1 < len(n.Content); i += 2 {
		if n.Content[i].Value == key {
			return n.Content[i+1]
		}
	}
	return nil
}
func put(n *yaml.Node, key string, value any) error {
	var v yaml.Node
	if err := v.Encode(value); err != nil {
		return err
	}
	for i := 0; i+1 < len(n.Content); i += 2 {
		if n.Content[i].Value == key {
			v.HeadComment = n.Content[i+1].HeadComment
			v.LineComment = n.Content[i+1].LineComment
			n.Content[i+1] = &v
			return nil
		}
	}
	n.Content = append(n.Content, &yaml.Node{Kind: yaml.ScalarNode, Tag: "!!str", Value: key}, &v)
	return nil
}
func drop(n *yaml.Node, key string) {
	for i := 0; i+1 < len(n.Content); i += 2 {
		if n.Content[i].Value == key {
			n.Content = append(n.Content[:i], n.Content[i+2:]...)
			return
		}
	}
}
func mapping() *yaml.Node { return &yaml.Node{Kind: yaml.MappingNode, Tag: "!!map"} }
func ensureMap(n *yaml.Node, key string) *yaml.Node {
	if v := field(n, key); v != nil {
		return v
	}
	v := mapping()
	n.Content = append(n.Content, &yaml.Node{Kind: yaml.ScalarNode, Tag: "!!str", Value: key}, v)
	return v
}
func yamlBytes(value any, comment string) ([]byte, error) {
	var b bytes.Buffer
	if comment != "" {
		b.WriteString(comment)
		b.WriteString("\n")
	}
	e := yaml.NewEncoder(&b)
	e.SetIndent(2)
	if err := e.Encode(value); err != nil {
		return nil, err
	}
	if err := e.Close(); err != nil {
		return nil, err
	}
	return b.Bytes(), nil
}
func writeChanged(path string, b []byte, write bool) (bool, error) {
	old, err := os.ReadFile(path)
	if err != nil && !os.IsNotExist(err) {
		return false, err
	}
	if bytes.Equal(old, b) {
		return false, nil
	}
	if write {
		if err = os.MkdirAll(filepath.Dir(path), 0755); err != nil {
			return false, err
		}
		if err = os.WriteFile(path, b, 0644); err != nil {
			return false, err
		}
	}
	return true, nil
}
func readSnapshot(path string) (Snapshot, error) {
	var s Snapshot
	b, e := os.ReadFile(path)
	if e == nil {
		e = json.Unmarshal(b, &s)
	}
	return s, e
}
