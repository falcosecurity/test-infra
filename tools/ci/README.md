# Infrastructure validation

## OCI Terraform plan and apply

The [OCI workflow](../../.github/workflows/terraform-oci.yml) is separate from
AWS and runs on GitHub-hosted `ubuntu-24.04` runners. GitHub OIDC tokens are
exchanged for temporary OCI security tokens; no OKE runner or registered OCI API
signing key is required. Platform changes merged into `master` trigger a fresh
plan and automatically apply that exact saved plan when changes exist and the
repository variable `OCI_TERRAFORM_APPLY_ENABLED` is `true`. The merge is the
approval; there is no per-run manual apply gate. Bootstrap and documentation-only
changes do not trigger it. Runs are serialized and resolve the current `master` after
acquiring concurrency, so queued old push events do not restore older code.

The [preflight helper](preflight-terraform-oci.sh) checks the backend, production
inputs and reviewed PR head without OCI credentials. It reads the Terraform
version and immutable revision from the trusted `master` checkout. The workflow
selects the plan/apply environment and Terraform revision using YAML expressions;
failed preflight checks prevent the credentialed job from starting. Domain URL
and client ID formats are validated by the session helper before token exchange.

The workflow exposes separate formatting, authentication, initialization,
validation, existing-state verification, planning, summary, apply and cleanup
steps. The [session helper](oci-session.sh) owns only OCI authentication,
credential renewal and private command output. Its `run <stage> <command>`
interface leaves every Terraform command visible in the workflow. The helper
comes from the immutable `master` revision selected during preflight, in a
separate checkout from the Terraform revision being planned.

A maintainer
can additionally dispatch a speculative cloud plan from the workflow on `master`,
selecting `operation=plan` and specifying the PR number and exact reviewed head
SHA. The workflow rejects a closed PR, a non-master base or a changed head.
Dispatch never applies, never
publishes a PR comment, and never passes its saved plan to a later deployment.
Review the entire Terraform change before dispatch: provider/module/data-source
code can access the runner's identity and state even during planning.

For identity and backend verification, dispatch `operation=verify` from `master`
with both PR inputs empty. It runs the same initialization, validation, state
checks and Terraform plan sequentially with the plan and apply environments.
Both use only the resolved, immutable `master` revision; neither runs apply.
This checks token exchange and the read/lock permissions exercised by the plan,
not every IAM permission or rejection of nonconforming tokens. Review reported
changes before enabling automatic deployment.

Keep `OCI_TERRAFORM_APPLY_ENABLED` unset or `false` during initial verification
or a deployment pause. Push runs report that automatic deployment is disabled
and do not start a credentialed Terraform job. Manual verification and reviewed
PR plans remain available. Set the repository variable to `true` only after
verifying the trust and both identities' permissions. Changing it does not
trigger a deployment or cancel a running one; coordinate changes with active
runs. It does not disable the OCI trust or revoke issued credentials.

### Activation prerequisites

Configure these prerequisites before using the workflow. They are managed
separately from the platform stack. Missing configuration fails preflight.

1. Configure an OCI Identity Domains confidential OAuth application for token
   exchange, without Identity Domain Administrator or other admin roles. This
   application is managed manually; never import its client secret into Terraform.
   The [manual bootstrap](../../config/clusters/oci/bootstrap/README.md#github-authentication)
   manages the separate plan/apply service users, groups, grants and trust.
   The workflow must not grant itself access. Follow
   [Oracle's JWT-to-UPST configuration](https://docs.oracle.com/en-us/iaas/Content/Identity/api-getstarted/json_web_token_exchange.htm).
2. Configure an Identity Propagation Trust for issuer
   `https://token.actions.githubusercontent.com`, its published JWKS, audience
   `https://cloud.oracle.com`, and the application's client ID. Require the exact
   `workflow_ref` claim
   `falcosecurity/test-infra/.github/workflows/terraform-oci.yml@refs/heads/master`.
   Map the two environment subjects to their respective service users, with
   exact matching and no wildcard fallback:

   | GitHub OIDC subject | OCI identity |
   | --- | --- |
   | `repo:falcosecurity/test-infra:environment:oci-terraform-plan` | Plan service user |
   | `repo:falcosecurity/test-infra:environment:oci-terraform-apply` | Apply service user |

   These subjects use GitHub's default subject format. Check the repository's
   OIDC configuration and other federation integrations before changing it.
   Validate the trust's claim enforcement before automatic deployment, including
   rejection of another repository, workflow, ref, environment, audience or runner
   type. Test one mismatched claim at a time; a stored rule or a no-change
   Terraform plan does not establish that token exchange enforces it. An environment
   alone does not restrict access to a particular workflow. See
   [GitHub's OIDC claims](https://docs.github.com/en/actions/reference/security/oidc).
3. Grant each service user only its required OCI permissions. Plan needs
   resource/state reads and write access only to the backend's lock object,
   not write access to the state object; apply additionally needs state writes
   and the mutations defined by this stack. Review the tenancy/home-region IAM and
   Identity Domains resources explicitly: do not grant tenancy-wide
   `manage all-resources` to make a failed plan work. Neither identity may alter
   its own federation trust, service-user membership or authorization policies.
4. In GitHub **Settings → Environments**, create `oci-terraform-plan` and
   `oci-terraform-apply`. For each, select **Selected branches and tags**, add a
   **Branch** rule for exactly `master`, and add no tag rules. Leave required
   reviewers and wait timers disabled: a manual dispatch authorizes a reviewed
   plan, and the merge authorizes automatic apply. In each environment add the
   secret `OCI_OIDC_CLIENT_SECRET`, containing the same token-exchange
   application's raw client secret. Do not store it as a repository secret or
   use an administrator application's secret. See
   [GitHub environment setup](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments).
5. Under **Settings → Secrets and variables → Actions → Variables**, configure
   these repository variables with reviewed, non-secret values:

   | Variable | Required value |
   | --- | --- |
   | `OCI_OIDC_DOMAIN_URL` | Identity domain URL, `https://<domain>.identity.oraclecloud.com`, without a trailing slash |
   | `OCI_OIDC_CLIENT_ID` | Token-exchange application's client ID |
   | `OCI_TERRAFORM_BACKEND` | JSON object with exactly `bucket`, `namespace`, `key`, `region` for the existing platform state |
   | `OCI_TERRAFORM_VARIABLES` | JSON representation of the approved platform inputs, explicitly including cluster name/versions, pinned node images, node pools and API CIDRs |

   Use the existing state location; do not infer it from the example backend
   file. Preserve all production overrides when preparing the input JSON.
   Frankfurt is required for both backend and platform region. IAM's
   `home_region` is configured only in the manual bootstrap. Bucket and namespace
   must agree between backend and platform inputs. Do not put API keys, private keys,
   tokens, HMAC values or state contents in repository variables.
6. Verify the native backend's existing default-workspace state and locking with
   the federated identities. The workflow refuses a
   backend that lacks `oci_containerengine_cluster.this` or contains managed
   IAM resources; it is not a first-install or bootstrap workflow. IAM belongs
   to the [manual bootstrap](../../config/clusters/oci/bootstrap/), whose state
   must not be accessible to either CI identity. Verify that plan cannot perform
   platform mutations or acquire the apply identity. Test a reviewed no-change plan before the
   first automatic deployment. See the
   [OCI backend](https://developer.hashicorp.com/terraform/language/backend/oci).

GitHub dispatch requires the workflow to exist on the default branch.
Credential-free PR validation does not exercise federation or backend access.

The OAuth client secret is the only persistent OCI credential used by this
workflow. It cannot replace the required GitHub OIDC assertion. The workflow
generates a signing key per job and selects `SecurityToken` for both backend and
providers. The helper obtains a fresh token before each wrapped command and
renews it every five minutes while that command runs, using the same ephemeral
key and atomically replacing the token file. Each command's renewal process is
stopped and reaped before its step exits; no renewal daemon is left running
between steps. Renewal failure fails the step and prevents subsequent Terraform
stages; there is no fallback to API keys or another identity.

Terraform and providers use the committed version/lock file. The native OCI
[backend](https://github.com/hashicorp/terraform/blob/v1.15.6/internal/backend/remote-state/oci/util.go)
uses `OCI_HOME_OVERRIDE` and the
[provider](https://github.com/oracle/terraform-provider-oci/blob/v8.16.0/internal/utils/helpers.go)
uses `TF_HOME_OVERRIDE`, both pointing to the private run directory rather than
an existing OCI configuration.
Raw logs, credentials, variables, state metadata and saved plans stay there.
Failed session initialization removes its own files; after successful
initialization, an `always()` workflow step removes them even if a Terraform
step fails. Only stage results and action counts reach the log; no plan/state
artifacts are uploaded. GitHub-hosted runner disposal also covers forced
termination where cleanup cannot run.
