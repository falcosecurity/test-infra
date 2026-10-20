// SPDX-License-Identifier: Apache-2.0
package main

import (
	"context"
	"encoding/base64"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

const botLogin = "poiana"
const botEmail = "51138685+poiana@users.noreply.github.com"

func git(ctx context.Context, dir string, env []string, args ...string) (string, error) {
	c := exec.CommandContext(ctx, "git", args...)
	c.Dir = dir
	c.Env = append(os.Environ(), env...)
	b, err := c.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("git %s: %w: %s", args[0], err, strings.TrimSpace(string(b)))
	}
	return strings.TrimSpace(string(b)), nil
}
func clone(ctx context.Context, parent, repo, branch string) (string, error) {
	dir := filepath.Join(parent, repo)
	_, err := git(ctx, parent, nil, "-c", "core.hooksPath=/dev/null", "clone", "--depth=1", "--branch", branch, "https://github.com/"+organization+"/"+repo+".git", dir)
	return dir, err
}

type pull struct {
	Number int    `json:"number"`
	Title  string `json:"title"`
	Body   string `json:"body"`
	User   struct {
		Login string `json:"login"`
	} `json:"user"`
	Head struct {
		SHA string `json:"sha"`
	} `json:"head"`
}

func (g *GitHub) botPull(ctx context.Context, repo, branch string) (*pull, error) {
	var pulls []pull
	if err := g.request(ctx, "GET", "/repos/"+organization+"/"+repo+"/pulls?state=open&head="+organization+":"+branch, nil, &pulls); err != nil {
		return nil, err
	}
	if len(pulls) > 1 {
		return nil, fmt.Errorf("multiple PRs for %s/%s", repo, branch)
	}
	if len(pulls) == 0 {
		return nil, nil
	}
	p := pulls[0]
	if p.User.Login != botLogin {
		return nil, fmt.Errorf("refusing to update a PR not authored by %s", botLogin)
	}
	var commits []struct {
		Author *struct {
			Login string `json:"login"`
		} `json:"author"`
	}
	if err := g.request(ctx, "GET", fmt.Sprintf("/repos/%s/%s/pulls/%d/commits?per_page=100", organization, repo, p.Number), nil, &commits); err != nil {
		return nil, err
	}
	if len(commits) == 100 {
		return nil, fmt.Errorf("too many commits in bot PR to verify ownership")
	}
	for _, c := range commits {
		if c.Author == nil || c.Author.Login != botLogin {
			return nil, fmt.Errorf("PR #%d contains a human/unknown commit; refusing to overwrite it", p.Number)
		}
	}
	return &p, nil
}
func signingEnvironment(ctx context.Context, parent, key string) ([]string, error) {
	if key == "" {
		return nil, fmt.Errorf("--gpg-key is required with --publish")
	}
	home := filepath.Join(parent, "gnupg")
	if err := os.Mkdir(home, 0700); err != nil {
		return nil, err
	}
	c := exec.CommandContext(ctx, "gpg", "--batch", "--homedir", home, "--import", key)
	if b, err := c.CombinedOutput(); err != nil {
		return nil, fmt.Errorf("import signing key: %w: %s", err, b)
	}
	c = exec.CommandContext(ctx, "gpg", "--batch", "--homedir", home, "--with-colons", "--list-secret-keys", botEmail)
	b, err := c.Output()
	if err != nil {
		return nil, fmt.Errorf("find bot signing key: %w", err)
	}
	keyID := ""
	for _, line := range strings.Split(string(b), "\n") {
		fields := strings.Split(line, ":")
		if len(fields) > 9 && fields[0] == "fpr" {
			keyID = fields[9]
			break
		}
	}
	if keyID == "" {
		return nil, fmt.Errorf("no signing key for %s", botEmail)
	}
	return []string{"GNUPGHOME=" + home, "GIT_CONFIG_COUNT=5", "GIT_CONFIG_KEY_0=user.name", "GIT_CONFIG_VALUE_0=" + botLogin, "GIT_CONFIG_KEY_1=user.email", "GIT_CONFIG_VALUE_1=" + botEmail, "GIT_CONFIG_KEY_2=commit.gpgsign", "GIT_CONFIG_VALUE_2=true", "GIT_CONFIG_KEY_3=user.signingkey", "GIT_CONFIG_VALUE_3=" + keyID, "GIT_CONFIG_KEY_4=core.hooksPath", "GIT_CONFIG_VALUE_4=/dev/null"}, nil
}

func (g *GitHub) publish(ctx context.Context, dir, repo, base, branch, title, body string, files []string, signEnv []string) error {
	p, err := g.botPull(ctx, repo, branch)
	if err != nil {
		return err
	}
	if len(files) == 0 {
		if p != nil {
			return g.request(ctx, "PATCH", fmt.Sprintf("/repos/%s/%s/pulls/%d", organization, repo, p.Number), map[string]string{"state": "closed"}, nil)
		}
		return nil
	}
	baseSHA, err := git(ctx, dir, nil, "rev-parse", "HEAD")
	if err != nil {
		return err
	}
	current, err := g.head(ctx, repo, base)
	if err != nil {
		return err
	}
	if baseSHA != current {
		return fmt.Errorf("%s base changed; retry reconciliation", repo)
	}
	add := append([]string{"add", "--"}, files...)
	if _, err = git(ctx, dir, signEnv, add...); err != nil {
		return err
	}
	// Compare content, not commit timestamps: a daily repair must not invalidate
	// reviews on an unchanged proposal. Source-evidence text can lag until content changes.
	if p != nil {
		var remote struct {
			Tree struct {
				SHA string `json:"sha"`
			} `json:"tree"`
		}
		if err = g.request(ctx, "GET", "/repos/"+organization+"/"+repo+"/git/commits/"+p.Head.SHA, nil, &remote); err != nil {
			return err
		}
		tree, e := git(ctx, dir, nil, "write-tree")
		if e != nil {
			return e
		}
		if tree == remote.Tree.SHA {
			return nil
		}
	}
	if _, err = git(ctx, dir, signEnv, "commit", "-s", "-m", title); err != nil {
		return err
	}
	// Credentials travel in the child environment, never URLs, arguments or logs.
	pushEnv := append(append([]string(nil), signEnv...), "GIT_CONFIG_COUNT=6", "GIT_CONFIG_KEY_5=http.https://github.com/.extraheader", "GIT_CONFIG_VALUE_5=AUTHORIZATION: basic "+base64.StdEncoding.EncodeToString([]byte("x-access-token:"+g.Token)))
	expected := ""
	if p != nil {
		expected = p.Head.SHA
	} else {
		remote, e := git(ctx, dir, pushEnv, "ls-remote", "origin", "refs/heads/"+branch)
		if e != nil {
			return e
		}
		if remote != "" {
			expected = strings.Fields(remote)[0]
			var closed []struct {
				pull
				MergedAt *string `json:"merged_at"`
			}
			if e = g.request(ctx, "GET", "/repos/"+organization+"/"+repo+"/pulls?state=closed&head="+organization+":"+branch+"&sort=updated&direction=desc&per_page=1", nil, &closed); e != nil {
				return e
			}
			if len(closed) != 1 || closed[0].User.Login != botLogin || closed[0].MergedAt == nil || closed[0].Head.SHA != expected {
				return fmt.Errorf("branch %s has no matching merged bot PR; inspect it before retrying", branch)
			}
		}
	}
	if _, err = git(ctx, dir, pushEnv, "push", "--force-with-lease=refs/heads/"+branch+":"+expected, "origin", "HEAD:refs/heads/"+branch); err != nil {
		return err
	}
	if p != nil {
		return g.request(ctx, "PATCH", fmt.Sprintf("/repos/%s/%s/pulls/%d", organization, repo, p.Number), map[string]string{"title": title, "body": body}, nil)
	}
	return g.request(ctx, "POST", "/repos/"+organization+"/"+repo+"/pulls", map[string]any{"title": title, "body": body, "head": branch, "base": base, "maintainer_can_modify": false}, nil)
}

func synchronize(ctx context.Context, g *GitHub, o options) error {
	parent, err := os.MkdirTemp(o.WorkDir, "project-sync-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(parent)
	var signEnv []string
	if o.Publish {
		var user struct {
			Login string `json:"login"`
		}
		if err = g.request(ctx, "GET", "/user", nil, &user); err != nil {
			return err
		}
		if user.Login != botLogin {
			return fmt.Errorf("publishing requires %s, got %s", botLogin, user.Login)
		}
		signEnv, err = signingEnvironment(ctx, parent, o.GPGKey)
		if err != nil {
			return err
		}
	}
	s, err := g.snapshot(ctx)
	if err != nil {
		return err
	}
	projectRef, ok := s.Repositories[".project"]
	if !ok {
		return fmt.Errorf(".project missing from inventory")
	}
	dir, err := clone(ctx, parent, ".project", projectRef.DefaultBranch)
	if err != nil {
		return err
	}
	if err = checkCheckout(ctx, dir, projectRef); err != nil {
		return err
	}
	p, err := loadProject(dir)
	if err != nil {
		return err
	}
	r, err := reconcile(p, s)
	if err != nil {
		return err
	}
	changed, err := applyResult(dir, r, true)
	if err != nil {
		return err
	}
	fmt.Println("Metadata changes:", changed)
	for _, line := range r.Summary {
		fmt.Println(line)
	}
	body := "Reconcile project metadata from merged OWNERS files. Active approvers and reviewers qualify for organization membership; emeritus maintainers retain existing membership without new invitations. Review the metadata diff for membership and team changes.\n\nGenerated by `test-infra/tools/project-sync`. Update source OWNERS or editable metadata fields instead of this branch.\n\n" + snapshotEvidence(s) + "\n/kind cleanup\n"
	if o.Publish {
		if err = g.verifySnapshot(ctx, s); err != nil {
			return err
		}
		if err = g.publish(ctx, dir, ".project", projectRef.DefaultBranch, "project-sync/metadata", "chore(metadata): synchronize repository ownership", body, changed, signEnv); err != nil {
			return err
		}
	}
	// Derived changes must be accepted in .project before docs and Special OWNERS.
	if len(changed) > 0 {
		return nil
	}
	if err = validateMetadata(p); err != nil {
		return err
	}
	infra := s.Repositories["test-infra"]
	infraDir, err := clone(ctx, parent, "test-infra", infra.DefaultBranch)
	if err != nil {
		return err
	}
	jobs, err := renderJobs(p)
	if err != nil {
		return err
	}
	jobFiles, err := applyResult(infraDir, jobs, true)
	if err != nil {
		return err
	}
	fmt.Println("Trigger changes:", jobFiles)
	if o.Publish {
		if err = g.publish(ctx, infraDir, "test-infra", infra.DefaultBranch, "project-sync/triggers", "chore(prow): synchronize ownership triggers", "Update ownership triggers from the accepted .project repository catalog.\n\n/kind cleanup\n", jobFiles, signEnv); err != nil {
			return err
		}
	}
	evo := s.Repositories["evolution"]
	evoDir, err := clone(ctx, parent, "evolution", evo.DefaultBranch)
	if err != nil {
		return err
	}
	if err = checkCheckout(ctx, evoDir, evo); err != nil {
		return err
	}
	docFiles, err := render(p, evoDir, true)
	if err != nil {
		return err
	}
	fmt.Println("Documentation changes:", docFiles)
	if o.Publish {
		if err = g.publish(ctx, evoDir, "evolution", evo.DefaultBranch, "project-sync/documentation", "docs: synchronize project metadata", "Update generated documentation from the accepted .project metadata.\n\nSource: https://github.com/falcosecurity/.project/commit/"+projectRef.SHA+"\n\n/kind documentation\n", docFiles, signEnv); err != nil {
			return err
		}
	}
	for _, repo := range r.Catalog {
		if repo.Scope != "Special" {
			continue
		}
		ref := s.Repositories[repo.Name]
		b, e := specialOwners(ref.Files["OWNERS"], r.Core)
		if e != nil {
			return fmt.Errorf("%s: %w", repo.Name, e)
		}
		repoDir := ""
		switch repo.Name {
		case ".project":
			repoDir = dir
		case "evolution":
			repoDir = evoDir
		default:
			repoDir, e = clone(ctx, parent, repo.Name, ref.DefaultBranch)
			if e != nil {
				return e
			}
		}
		// Documentation may have been committed above. Each proposal starts at its own base.
		if repo.Name == "evolution" {
			if _, e = git(ctx, repoDir, nil, "reset", "--hard", "origin/"+ref.DefaultBranch); e != nil {
				return e
			}
		}
		if e = checkCheckout(ctx, repoDir, ref); e != nil {
			return e
		}
		yes, e := writeChanged(filepath.Join(repoDir, "OWNERS"), b, true)
		if e != nil {
			return e
		}
		var files []string
		if yes {
			files = []string{"OWNERS"}
		}
		fmt.Println("Special OWNERS changes:", repo.Name, yes)
		if o.Publish {
			if e = g.publish(ctx, repoDir, repo.Name, ref.DefaultBranch, "project-sync/core-owners", "chore(owners): synchronize core maintainers", "Synchronize root approvers with the core-maintainers roster.\n\nSource: https://github.com/falcosecurity/.project/commit/"+projectRef.SHA+"\n\n/kind cleanup\n", files, signEnv); e != nil {
				return e
			}
		}
	}
	return nil
}
func checkCheckout(ctx context.Context, dir string, ref RepoSnapshot) error {
	sha, err := git(ctx, dir, nil, "rev-parse", "HEAD")
	if err != nil {
		return err
	}
	if sha != ref.SHA {
		return fmt.Errorf("%s changed after snapshot; retry", ref.Name)
	}
	return nil
}
func snapshotEvidence(s Snapshot) string {
	names := make([]string, 0, len(s.Repositories))
	for n, r := range s.Repositories {
		if !r.Archived {
			names = append(names, n)
		}
	}
	sort.Strings(names)
	var b strings.Builder
	b.WriteString("<details><summary>OWNERS source commits (" + strconv.Itoa(len(names)) + " repositories)</summary>\n\n")
	for _, name := range names {
		fmt.Fprintf(&b, "- `%s`: `%s`\n", name, s.Repositories[name].SHA)
	}
	b.WriteString("\n</details>\n")
	return b.String()
}
