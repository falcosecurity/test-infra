# Infrastructure validation

The [CI workflow](../../.github/workflows/ci.yml) selects the
[AWS](../../.github/workflows/ci-aws.yml) and
[OCI](../../.github/workflows/ci-oci.yml) validation workflows from the PR merge
diff. It reads both sides of renames and does not use GitHub's truncated path-filter
file list. Selection rules and gate tests live in
[changes.mjs](changes.mjs) and [changes.test.mjs](changes.test.mjs).

| Changed area | Checks |
| --- | --- |
| Cloud-specific configuration or tooling | That cloud |
| Shared CI tooling or configuration | AWS and OCI |
| OCI bootstrap only | Neither; validate locally |
| Documentation or DriverKit generated catalog only | Neither; existing dedicated checks remain |

The required `manifests-validation` context always reports the combined result.
A failed selector, failed validation or unexpectedly skipped cloud blocks it.
These workflows use read-only repository permissions, no cloud credentials, and
no deployment commands. The required AWS Prow
`check-prow-config` presubmit is unchanged. In particular, that Prow presubmit
still runs on all PRs until its required-context transition is coordinated.

## Validation scope

- AWS retains its existing Prow schema policy and Terrascan rule exceptions.
  Its job checker is built once and runs without GitHub API requests. The two old
  checker workflows have been consolidated into the AWS workflow.
- OCI checks both raw manifests (including Hook and plugins) and the Kustomize
  bundle. Custom-resource schemas come from the chart versions in the Argo CD
  Applications. Argo CD schemas use the chart version in each bootstrap script.
  This validates resource schemas, not every Helm value or live admission policy.
- The OCI ProwJob CRD is checked byte-for-byte against its pinned upstream source,
  rather than silently skipped. Other OCI resources require a schema.
- OCI dashboard [branding tests](verify-branding.test.mjs) verify the official
  logo and favicon, rendered ConfigMap references and read-only asset mount.
- The separate OCI `jobs-checker` job validates core/plugins and any future job
  catalog using [verify-prow.sh](verify-prow.sh) and the pinned Prow `checkconfig`
  image, with networking disabled inside the validator container. Both `.yaml`
  and `.yml` job files are included. Updating Prow also requires updating the
  shared release pins in [prow-version.sh](prow-version.sh).
- [Terraform validation](verify-terraform.sh) copies only the OCI root Terraform
  sources and provider lock file into a temporary directory. It runs formatting,
  initialization with `-backend=false -lockfile=readonly`, and validation. It does
  not copy state, tfvars, backend configuration files, or the bootstrap stack.

## Local checks

Run from the repository root:

```sh
node --test tools/ci/changes.test.mjs
node --test tools/ci/verify-prow.test.mjs
node --test tools/ci/verify-branding.test.mjs
bash tools/ci/apply-terraform-aws.test.sh
node tools/ci/changes.mjs upstream/master HEAD
bash tools/ci/verify-manifests.sh aws
bash tools/ci/verify-manifests.sh oci
bash tools/ci/verify-prow.sh
bash tools/ci/verify-terraform.sh
```

Use Node.js 20 or newer, kubeconform 0.8.0, Kustomize 5.7.1, yq 4.52.4, Helm
4.0.4, and Python with PyYAML 6.0.3. The Linux CI
[installer](install-tools.sh) verifies the downloaded tool checksums. For native
local tools, set `OPENAPI2JSONSCHEMA` to kubeconform 0.8.0's
[upstream converter](https://github.com/yannh/kubeconform/blob/v0.8.0/scripts/openapi2jsonschema.py).
OCI `checkconfig` needs Docker; outside CI, `CHECKCONFIG_BIN` can point to a native
binary built from Prow commit `cafa494600840c6b58f9b765aa7133ca6e82bb48`.
Terraform uses the version in the OCI stack's version file.

Manifest checks download public charts and schemas. Terraform initialization
downloads public provider packages. Neither requires cluster access or secrets.
End-to-end workload behavior and server-side admission remain separate checks.

## Automatic AWS Terraform apply

The [AWS apply workflow](../../.github/workflows/terraform-apply.yml) runs after
changes to the AWS stack or its apply automation reach `master`. The merge is
the authorization: no additional deployment approval is required. OCI-only
changes do not trigger it.

[apply-terraform-aws.sh](apply-terraform-aws.sh) checks formatting, initializes
with the committed provider lock file, validates the configuration, and saves
a plan in a private temporary directory. A plan with no changes finishes
successfully without applying. A plan with changes is applied automatically
from that exact saved file in the same job. Any failed prerequisite, planning
error, or failed apply fails the job; it does not silently generate another plan.

Backend locking and the existing shared deployment concurrency group remain
enabled. Plans and raw Terraform output are not uploaded as artifacts or
published in logs; the helper reports stages and resource-action counts. The
temporary files are removed when the helper exits. Diagnosing a failed stage
may require an authorized reproduction because the raw diagnostics are private
and ephemeral.

The [Bash regression tests](apply-terraform-aws.test.sh) use a simulated Terraform
executable, not cloud credentials or state. They run in the AWS validation
workflow. The [PR plan](../../.github/workflows/terraform-plan.yml) remains
speculative and is not reused for deployment. Both workflows pin Terraform
1.15.6; the AWS provider versions and backend configuration are unchanged.
