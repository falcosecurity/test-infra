# GitHub organization management

OCI Prow runs Peribolos against the authoritative
[`.project/config/org.yaml`](https://github.com/falcosecurity/.project/blob/main/config/org.yaml).
It applies accepted changes to organization membership, settings, teams, and
repository permissions after that file merges and every 24 hours. The presubmit
job provides a dry run. Existing Peribolos change limits remain enabled.

## Updating ownership and metadata

Change approvers, reviewers, and emeritus roles in repository `OWNERS` files.
The [project-sync tool](../tools/project-sync/README.md) opens reviewed PRs to
reconcile `.project` metadata, evolution documentation, and Special repository
ownership. Metadata edits also trigger reconciliation; daily recovery catches
missed events. See [rollout instructions](project-sync-rollout.md) for the migration.

All approvers and reviewers from root and nested OWNERS join the repository's
GitHub team. Only approvers enter the CNCF repository roster. Root approvers of
Core repositories form `core-maintainers`; Special root approvers follow that
roster through bot PRs, including `elftoolchain`.

Active approvers and reviewers qualify for organization membership. Emeritus
maintainers retain existing membership when present in both GitHub and the accepted
`org.yaml`; absent emeritus-only accounts are not invited. Former reviewers have no
emeritus retention exception. The manually edited `admins` list is preserved.
Archived repositories contribute no roles and are removed from all active metadata.
Otherwise, removing the last eligible role removes organization membership.

Honor an emeritus-only maintainer's requested departure by removing their membership
from `org.yaml` through a reviewed PR. Keep historical OWNERS entries. Record
out-of-band departures before the next Peribolos run, which applies accepted YAML.
Verified historical renames may use `github_id` and `emeritus_aliases` in affiliations;
these preserve existing membership without granting review permissions.
Invalid active accounts stop reconciliation; invalid emeritus accounts are omitted
and reported. Failed membership/account reads stop the run.

In generated teams, eligible organization admins have the GitHub team `maintainer`
role; everyone else is a `member`. Purpose-specific teams remain manually managed.
Their people must still satisfy organization eligibility; conflicts stop the run
and require an explicit edit. These team roles do not change OWNERS permissions.

Edit repository descriptions/settings, organization settings/admins, and
purpose-specific teams in `.project/config/org.yaml`; edit scope/status in
`config/repository.yaml` and display names/companies in `config/affiliations.yaml`.
Each metadata file documents its editable fields. Apart from requested emeritus-only
departures, organization membership is generated. Do not edit generated rosters or
repository/core team membership directly.

## How do pull request approvals work?

The OCI Prow configuration uses the same review policy across repositories,
including `falco` and `libs`: one GitHub approving review, plus the `approved` and
`lgtm` labels. Review permissions come from `OWNERS`, including directory scopes.

| PR author | GitHub approving review from | Outcome |
| --- | --- | --- |
| Non-approver | Approver covering all changed files | Both labels; eligible to merge |
| Non-approver | Reviewer only | `lgtm`; waits for an approver's `/approve` |
| Approver covering all changed files | Another eligible reviewer or approver | Author supplies `approved`; review supplies `lgtm`; eligible to merge |

An author's implicit approval covers only files they own. Approval must cover
every changed file, so changes across ownership boundaries may need additional
approvers. LGTM requires an OWNERS reviewer or approver for the changed files;
authors cannot LGTM their own PRs.

Comment commands do not replace the required GitHub approving review. New code
changes require renewed review: stale GitHub reviews are dismissed and LGTM is
removed when the tree changes. CI and all other merge requirements still apply.
The existing `falcoctl/gh-pages` publishing branch keeps its zero-review exception.

## What if I have further questions?

Please open an issue in this repo and someone from the Falco infra team will be happy to help!
