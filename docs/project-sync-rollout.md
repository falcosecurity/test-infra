# Project metadata migration rollout

This change spans `.project`, `test-infra`, and `evolution`. Review all three PRs
before activation. Branches and local migration previews alone do not change
GitHub membership or archive repositories.

1. Review the generated `.project` migration and its organization membership diff.
   The migration copies repository descriptions once from evolution into `org.yaml`.
   Invalid historical emeritus references are reported, not added as organization members.
2. Merge the `.project` PR to establish `config/org.yaml`, `config/repository.yaml`,
   `config/affiliations.yaml`, and the CNCF-format `maintainers.yaml`. Its validator
   references the tool commit from the companion test-infra PR, which must be pushed
   and accessible before running that workflow. Existing Peribolos still reads the
   old test-infra configuration during this step.
3. After the coordinated archival proposal is accepted, an organization admin must
   archive `falcosecurity/peribolos-syncer` on GitHub. Its jobs were already removed
   in test-infra PR #2024; the central tool now replaces it. The local migration's
   `--retire` option only models this planned step. Activation refuses an active
   repository missing from the catalog, so do not skip the actual archival.
4. Before merging test-infra, run the pinned Peribolos image against the accepted
   `.project/config/org.yaml` without `--confirm`, using its existing read credentials
   and `--fix-*` options. Review the membership delta. Then merge test-infra and wait
   for OCI deployment: this switches Peribolos to `.project`, enables project-sync,
   and removes the old generator. Existing removal limits and minimum-admin
   protection remain in force. The first periodic run can apply the new config.
5. Merge evolution to remove duplicate YAML/JSON metadata and its obsolete Go utils,
   publish the generated documentation, and document the new process. If the old
   generator opened a PR before shutdown, close that superseded PR after review.
6. Run `project-sync-reconcile` once and inspect its logs and bot PRs. Rebase or
   regenerate the migration preview if OWNERS changed during review. Accept metadata
   first, then documentation and Special OWNERS proposals, then any resulting team
   updates. Special repositories include `.github`, `.project`, `community`,
   `evolution`, and `elftoolchain`.

## Validation and rollback

Run the tool tests, OCI Prow and manifest checks, CNCF schema validators, and local
metadata/documentation generation before opening the PRs. Confirm a repeated
reconciliation against the same verified snapshot produces no changes. Check
organization additions/removals independently of team roles.

If activation fails, disable the project-sync jobs and Peribolos writes while
investigating. Git revert restores the previous configuration, but reverting Git
does not undo GitHub membership removals, invitations, or archival. Restore accepted
organization state deliberately through the authoritative config. Avoid running
both old and new generators at once. AWS is retired and remains outside this rollout.
