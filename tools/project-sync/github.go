// SPDX-License-Identifier: Apache-2.0
package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"path"
	"reflect"
	"sort"
	"strings"
	"sync"
	"time"
)

type GitHub struct {
	Token   string
	BaseURL string
	HTTP    *http.Client
}
type apiError struct {
	Method, Endpoint string
	Status           int
}

func (e *apiError) Error() string {
	return fmt.Sprintf("GitHub %s %s: HTTP %d", e.Method, e.Endpoint, e.Status)
}

func (g *GitHub) request(ctx context.Context, method, endpoint string, body, out any) error {
	var data []byte
	var err error
	if body != nil {
		data, err = json.Marshal(body)
		if err != nil {
			return err
		}
	}
	base := g.BaseURL
	if base == "" {
		base = "https://api.github.com"
	}
	req, err := http.NewRequestWithContext(ctx, method, base+endpoint, bytes.NewReader(data))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+g.Token)
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	req.Header.Set("Content-Type", "application/json")
	client := g.HTTP
	if client == nil {
		client = &http.Client{Timeout: 90 * time.Second}
	}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return &apiError{method, endpoint, resp.StatusCode}
	}
	if out != nil {
		return json.NewDecoder(io.LimitReader(resp.Body, 64<<20)).Decode(out)
	}
	return nil
}
func (g *GitHub) inventory(ctx context.Context) ([]RepoSnapshot, error) {
	var out []RepoSnapshot
	for page := 1; ; page++ {
		var entries []struct {
			Name          string `json:"name"`
			Archived      bool   `json:"archived"`
			Private       bool   `json:"private"`
			DefaultBranch string `json:"default_branch"`
		}
		if err := g.request(ctx, "GET", fmt.Sprintf("/orgs/%s/repos?type=all&per_page=100&page=%d", organization, page), nil, &entries); err != nil {
			return nil, err
		}
		for _, r := range entries {
			if !r.Private {
				out = append(out, RepoSnapshot{Name: r.Name, Archived: r.Archived, DefaultBranch: r.DefaultBranch})
			}
		}
		if len(entries) < 100 {
			break
		}
	}
	return out, nil
}
func (g *GitHub) head(ctx context.Context, repo, branch string) (string, error) {
	var ref struct {
		Object struct {
			SHA string `json:"sha"`
		} `json:"object"`
	}
	err := g.request(ctx, "GET", "/repos/"+organization+"/"+repo+"/git/ref/heads/"+url.PathEscape(branch), nil, &ref)
	return ref.Object.SHA, err
}
func (g *GitHub) members(ctx context.Context) (map[string]Account, error) {
	// Non-members can receive only the public membership list. Never treat
	// that partial response as evidence for organization removals.
	var membership struct {
		State string `json:"state"`
	}
	if err := g.request(ctx, "GET", "/user/memberships/orgs/"+organization, nil, &membership); err != nil {
		return nil, err
	}
	if membership.State != "active" {
		return nil, fmt.Errorf("complete membership scan requires an active organization member")
	}
	out := map[string]Account{}
	for page := 1; ; page++ {
		var entries []Account
		if err := g.request(ctx, "GET", fmt.Sprintf("/orgs/%s/members?role=all&per_page=100&page=%d", organization, page), nil, &entries); err != nil {
			return nil, err
		}
		for _, a := range entries {
			key := strings.ToLower(a.Login)
			if a.Type != "User" || a.ID <= 0 || !loginPattern.MatchString(a.Login) || out[key].ID != 0 {
				return nil, fmt.Errorf("invalid or duplicate account in organization membership response")
			}
			out[key] = a
		}
		if len(entries) < 100 {
			break
		}
	}
	return out, nil
}
func (g *GitHub) snapshot(ctx context.Context) (Snapshot, error) {
	repos, err := g.inventory(ctx)
	if err != nil {
		return Snapshot{}, err
	}
	out := Snapshot{Repositories: map[string]RepoSnapshot{}}
	var mu sync.Mutex
	var wg sync.WaitGroup
	var firstErr error
	semaphore := make(chan struct{}, 4)
	for _, r := range repos {
		if r.Archived {
			mu.Lock()
			out.Repositories[r.Name] = r
			mu.Unlock()
			continue
		}
		wg.Add(1)
		go func(r RepoSnapshot) {
			defer wg.Done()
			semaphore <- struct{}{}
			defer func() { <-semaphore }()
			result, e := g.readOwners(ctx, r)
			mu.Lock()
			defer mu.Unlock()
			if e != nil {
				if firstErr == nil {
					firstErr = e
				}
				return
			}
			out.Repositories[r.Name] = result
		}(r)
	}
	wg.Wait()
	if firstErr != nil {
		return out, firstErr
	}
	err = g.accounts(ctx, &out)
	return out, err
}
func (g *GitHub) accounts(ctx context.Context, s *Snapshot) error {
	members, err := g.members(ctx)
	if err != nil {
		return err
	}
	s.Members = members
	people := set{}
	for _, r := range s.Repositories {
		if r.Archived {
			continue
		}
		o, err := parseOwnership(r)
		if err != nil {
			return err
		}
		people.union(o.Approvers)
		people.union(o.Reviewers)
		people.union(o.Emeritus)
	}
	s.Accounts = map[string]Account{}
	for login, account := range members {
		s.Accounts[login] = account
	}
	for _, login := range people.list() {
		var account Account
		err := g.request(ctx, "GET", "/users/"+login, nil, &account)
		if err != nil {
			var ae *apiError
			if !errors.As(err, &ae) || ae.Status != 404 {
				return err
			}
		}
		s.Accounts[login] = account
	}
	return nil
}
func (g *GitHub) readOwners(ctx context.Context, r RepoSnapshot) (RepoSnapshot, error) {
	sha, err := g.head(ctx, r.Name, r.DefaultBranch)
	if err != nil {
		return r, err
	}
	r.SHA = sha
	r.Files = map[string]string{}
	var tree struct {
		Truncated bool `json:"truncated"`
		Tree      []struct {
			Path string `json:"path"`
			Type string `json:"type"`
			SHA  string `json:"sha"`
		} `json:"tree"`
	}
	if err = g.request(ctx, "GET", "/repos/"+organization+"/"+r.Name+"/git/trees/"+sha+"?recursive=1", nil, &tree); err != nil {
		return r, err
	}
	if tree.Truncated {
		return r, fmt.Errorf("%s tree is truncated; refusing incomplete OWNERS scan", r.Name)
	}
	for _, f := range tree.Tree {
		if f.Type != "blob" || (path.Base(f.Path) != "OWNERS" && f.Path != "OWNERS_ALIASES") {
			continue
		}
		var blob struct {
			Content  string `json:"content"`
			Encoding string `json:"encoding"`
			Size     int    `json:"size"`
		}
		if err = g.request(ctx, "GET", "/repos/"+organization+"/"+r.Name+"/git/blobs/"+f.SHA, nil, &blob); err != nil {
			return r, err
		}
		if blob.Encoding != "base64" || blob.Size > 1<<20 {
			return r, fmt.Errorf("unexpected OWNERS blob in %s", r.Name)
		}
		b, e := base64.StdEncoding.DecodeString(strings.ReplaceAll(blob.Content, "\n", ""))
		if e != nil {
			return r, e
		}
		r.Files[f.Path] = string(b)
	}
	return r, nil
}
func (g *GitHub) verifySnapshot(ctx context.Context, s Snapshot) error {
	members, err := g.members(ctx)
	if err != nil {
		return err
	}
	if !reflect.DeepEqual(members, s.Members) {
		return fmt.Errorf("organization membership changed; retry with a fresh snapshot")
	}
	current, err := g.inventory(ctx)
	if err != nil {
		return err
	}
	if len(current) != len(s.Repositories) {
		return fmt.Errorf("repository inventory changed; retry")
	}
	for _, repo := range current {
		old, ok := s.Repositories[repo.Name]
		if !ok || old.Archived != repo.Archived || old.DefaultBranch != repo.DefaultBranch {
			return fmt.Errorf("%s inventory changed; retry", repo.Name)
		}
	}
	names := make([]string, 0, len(s.Repositories))
	for n := range s.Repositories {
		names = append(names, n)
	}
	sort.Strings(names)
	for _, n := range names {
		r := s.Repositories[n]
		if r.Archived {
			continue
		}
		sha, err := g.head(ctx, n, r.DefaultBranch)
		if err != nil {
			return err
		}
		if sha != r.SHA {
			return fmt.Errorf("%s changed during reconciliation; rerun with a fresh snapshot", n)
		}
	}
	return nil
}
