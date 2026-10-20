# Project metadata migration rollout

This change spans `.project`, `test-infra`, and `evolution`. Review all three PRs
before activation. Branches and local migration previews alone do not change
GitHub membership or archive repositories.

1. Review the generated `.project` migration and its organization membership diff.
   The migration copies repository descriptions once from evolution into `org.yaml`.
   Use a fresh authenticated membership and account snapshot. Active roles qualify
   for membership; emeritus maintainers retain existing membership without new
   invitations. Verify historical renames against immutable account IDs, preserve
   requested departures, and report unusable historical entries without altering OWNERS.
2. Merge the `.project` PR to establish `config/org.yaml`, `config/repository.yaml`,
   `config/affiliations.yaml`, and the CNCF-format `maintainers.yaml`. Its validator
   references the tool commit from the companion test-infra PR, which must be pushed
   and accessible before running that workflow. Existing Peribolos still reads the
   old test-infra configuration during this step. The new org.yaml includes
   `repos.peribolos-syncer.archived: true` as a pending archival instruction;
   it is not evidence that GitHub has archived the repository yet.
3. Before merging test-infra, run the pinned Peribolos image against the accepted
   `.project/config/org.yaml` without `--confirm`, using its existing read credentials
   and `--fix-*` options. Review both the archival and membership delta.
   Ensure test-infra's marked temporary `config/org.yaml` is identical in YAML
   content to the accepted `.project/config/org.yaml`; regenerate the copy if needed.
   This preserves the existing presubmit and merge-time Peribolos jobs during
   deployment. Then merge test-infra and wait
   for OCI deployment: this switches Peribolos to `.project`, enables project-sync,
   and removes the old generator. Existing removal limits and minimum-admin
   protection remain in force.
   Refresh the reviewed membership diff if GitHub membership or OWNERS changed
   since the migration snapshot; do not apply a stale proposal.
4. Wait for Peribolos to archive `peribolos-syncer`. The existing merge job can
   consume the temporary migration copy; the new test-infra configuration postsubmit
   and the 24-hour periodic read `.project/main`. All apply jobs enable
   `--confirm`, `--fix-repos`, and `--allow-repo-archival`. The periodic covers a
   missed activation event during deployment. Confirm a successful apply run and
   GitHub's `archived: true` state; no manual GitHub archival is required.
   Until then, project-sync leaves the request intact and proposes no downstream
   changes. If archival fails, correct the reported issue and rerun Peribolos.
5. After archival is confirmed and the old generator is disabled, merge evolution
   to remove duplicate YAML/JSON metadata and its obsolete Go utils, publish
   documentation reflecting the completed retirement, and document the new process. If the old
   generator opened a PR before shutdown, close that superseded PR after review.
6. Run `project-sync-reconcile` and inspect its logs and bot PRs. It proposes
   removing the confirmed archival entry from `.project`; after that cleanup
   merges, its test-infra trigger PR also removes the marked temporary
   `config/org.yaml`. Neither copy remains as permanent metadata for archived
   repositories. Rebase or
   regenerate the migration preview if OWNERS changed during review. Accept metadata
   first, then documentation and Special OWNERS proposals, then any resulting team
   updates. Special repositories include `.github`, `.project`, `community`,
   `evolution`, and `elftoolchain`.

## Validation and rollback

Run the tool tests, OCI Prow and manifest checks, CNCF schema validators, and local
metadata/documentation generation before opening the PRs. Test both the pending
and confirmed archival states: pending requests must survive unchanged; confirmed
archives must produce cleanup; repeated reconciliation after accepting cleanup
must produce no changes. Check
organization additions/removals independently of team roles.

If activation fails, disable the project-sync jobs and Peribolos writes while
investigating. Git revert restores the previous configuration, but reverting Git
does not undo GitHub membership removals, invitations, or archival. Restore accepted
organization state deliberately through the authoritative config. Avoid running
both old and new generators at once. AWS is retired and remains outside this rollout.
