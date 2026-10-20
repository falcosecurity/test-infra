# project-sync

One Go command reconciles Falco ownership, project metadata, generated documentation,
and Special repository approvers. Prow runs it as `poiana`; Peribolos remains the
only component applying organization settings to GitHub.

## Sources

- All public, active organization repositories, at their default-branch commits.
- Root and nested `OWNERS`, with root `OWNERS_ALIASES` expansion using official Prow
  `repoowners` parsers. Supplemental parsing reads emeritus roles, which Prow ignores.
- `.project/config/repository.yaml`: name, scope, status.
- `.project/config/org.yaml`: official Prow `config/org` schema; editable settings,
  descriptions, admins, and purpose-specific teams.
- `.project/config/affiliations.yaml`: editable names, companies, and verified
  historical emeritus aliases.

Approvers and reviewers join repository teams; approvers alone populate CNCF
repository rosters. Root approvers of Core repositories form `core-maintainers`,
the only CNCF-managed team. Special ownership never grants core status.
Active approvers and reviewers qualify for organization membership. Emeritus
maintainers (`emeritus_approvers`) retain membership only when already present in
both GitHub and the accepted `org.yaml`. Absent emeritus-only accounts are never
invited. Former reviewers have no emeritus retention exception. Admins are
preserved; everyone else without an eligible role is removed. Archived repositories
do not count and are removed from metadata and permissions.

To honor a requested departure after all active roles have ended, remove the
emeritus-only member from `org.yaml` through a reviewed PR. Reconciliation preserves
that removal even before Peribolos applies it. Keep historical OWNERS entries.
An out-of-band departure should also be recorded in `org.yaml` before Peribolos next
runs, since Peribolos applies the accepted file independently.

For a verified historical rename, the canonical affiliation entry may specify
`github_id` and `emeritus_aliases`. The ID must match the current member's immutable
GitHub user ID. These aliases affect emeritus retention only; they cannot grant
active review permissions. Invalid active accounts fail the run. Invalid emeritus
accounts are omitted and reported without changing historical OWNERS. API failures
are errors, never evidence that a person disappeared.

Purpose-specific teams are preserved. If such a team retains an ineligible person,
reconciliation fails with an actionable conflict instead of overriding either the
membership rule or the manually maintained team. Removed public repositories must
be cleaned up explicitly; missing catalog snapshots stop reconciliation.

An explicit `archived: true` entry in `config/org.yaml` requests archival through
Peribolos. While GitHub still reports the repository as active, reconciliation
waits without rewriting metadata or publishing downstream PRs. The request can
remain outside the active catalog during migration. After GitHub confirms
archival, the bot proposes removing its metadata; accepting that cleanup releases
downstream generation. Removing a configuration entry alone never archives a repo.

## Local commands

Use Go 1.26 or later. Credentials are only required for GitHub reads or publication.
Local commands report changes unless `--write` is supplied. Snapshots contain public
ownership, account, and complete organization membership data, never tokens.
Membership reads require an authenticated active organization member with permission
to read the full membership list. Incomplete or unavailable membership stops the run.

```sh
go test -race ./...
go build -o /tmp/project-sync .

# GH_TOKEN or --github-token-path supplies read credentials.
/tmp/project-sync snapshot --output /tmp/owners.json
/tmp/project-sync reconcile --project-dir ../.project --snapshot /tmp/owners.json
/tmp/project-sync render --project-dir ../.project --evolution-dir ../evolution
/tmp/project-sync jobs --project-dir ../.project --test-infra-dir ../test-infra
/tmp/project-sync validate --project-dir ../.project

# Complete live preview: temporary clones only, no remote writes.
/tmp/project-sync sync
```

`validate` checks input syntax and editable catalog fields. It deliberately permits
derived drift: a repository registration can merge before its generated roster or
team exists. `render` requires consistent metadata; `sync` first reconciles it and
waits for the metadata PR to merge before proposing downstream changes.

`migrate` is a one-time local operation using legacy evolution metadata, a source
Peribolos file, and a verified snapshot. Its optional `--retire NAME` excludes a
planned retirement from the preview; it does not archive anything and is never
accepted by `sync`. `accounts` can refresh account verification in an offline
snapshot, including current membership. Production `sync` always fetches and
verifies accounts itself and rechecks membership before publishing.

## Prow and PR lifecycle

`job-template.yaml` is embedded in this binary. `jobs` generates the complete OCI
postsubmit catalog from accepted metadata, plus a 24-hour recovery job. The same
serialized `governance` queue is used by Peribolos. Jobs execute code from the
trusted test-infra `master`, never the triggering repository. A digest-pinned Go
image builds the tool with the locked module graph; it also provides Git and GPG.
This avoids a separate application-image publication dependency, at the cost of
compiling the tool and downloading its pinned dependencies per job.

Publishing requires `sync --publish`, a token belonging to `poiana`, and
`--gpg-key`. Commits are signed and DCO signed off. Tokens are passed to Git in the
child environment, never command arguments or remote URLs. Source snapshots and
target bases are checked before publication. Git pushes use an explicit lease.

Stable branches are `project-sync/metadata`, `project-sync/documentation`,
`project-sync/triggers`, and `project-sync/core-owners`. Unchanged trees do not
rewrite open PRs. Human-authored PRs or commits are never overwritten. A branch
without an open PR can be reused only when it matches a previously merged bot PR;
otherwise an operator must inspect it. Obsolete open bot PRs are closed. The tool
never approves or merges PRs and never archives repositories.

Each run stops after proposing metadata changes. Once those merge, it can propose
documentation, trigger-catalog, and Special OWNERS changes. Further merged OWNERS
changes then bring the repository teams into line. Daily recovery covers missed
events and newly registered repositories whose trigger PR has not merged yet.

During this migration, test-infra retains a marked, identical `config/org.yaml`
copy for jobs still using the old location. Both the old merge job and the new
Peribolos configuration postsubmit can apply the pending archival; the periodic
provides recovery. After archival and accepted metadata cleanup, the bot's
test-infra trigger PR removes that marked copy. It refuses to remove an unmarked
configuration. See the [rollout](../../docs/project-sync-rollout.md) for merge order.

To recover from failure, fix the reported input or transient API issue and rerun
`project-sync-reconcile` in Prow. Closed unmerged branches need operator inspection
before reuse. Never work directly on bot branches; edit authoritative sources.
