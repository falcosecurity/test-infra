# OCI Prow

The [Prow Application](../../applications/oci/prow.yaml) follows `master` and
automatically reconciles the [Kustomize bundle](kustomization.yaml). It owns
Deck, Hook, ghproxy, Prow Controller Manager, their RBAC, configuration and
branding. Hook uses PAT authentication and has no ConfigMap mutation permissions.
The [plugin configuration](plugins.yaml) is empty. No job catalog, Tide, Crier
or Horologium is configured in this bundle.

TLS and public routes remain owned by the separate
[gateway Application](../../applications/oci/gateway.yaml). Credentials are
externally provisioned Secrets; they are not generated or managed by this
Application. The retained ghproxy PVC and both namespaces require explicit
Argo CD deletion/pruning confirmation, as does the rendered ProwJob CRD.

## Deployment

The Application deploys from `master`. Provision the required Secrets and
StorageClass before syncing it.

1. Validate the sources with the CI tools and render
   `kustomize build config/prow/oci`. Check that no Secret is included.
2. Verify the intended OKE context, existing component health and that the
   `oci-bv-retain` StorageClass exists. Check existing resource ownership before
   sync. Do not take resources away from another Argo CD Application.
3. Ensure no `config-updater`, custom config uploader or manual reconciliation
   loop is writing these ConfigMaps. The Application is their sole writer.
4. Apply the
   [Prow Application](../../applications/oci/prow.yaml) to OKE. This starts its
   automatic sync from `master`; do not run the entire Argo CD bootstrap script
   for a Prow-only deployment, because that also installs other Applications.
5. Verify the Application is Synced/Healthy and compare the rendered desired
   configuration with the applied non-secret resources. Check Deck and Hook
   rollouts, ghproxy PVC binding, public dashboard/TLS and component logs for
   configuration reload or permission errors. Do not print Secret contents.
6. Manage subsequent configuration changes through the repository. Argo CD
   reconciles merges to `master`; avoid concurrent manual writes to its resources.

Argo CD uses server-side apply for the CRD and existing resources, fails on
resources owned by another Application, and prunes obsolete resources last.
Namespaces, the cache PVC and the CRD are protected from automatic removal.
See [Argo CD sync options](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/).

## Recovery

If reconciliation fails, pause automatic sync before changing live resources.
Revert the affected configuration and sync the reviewed revision. Preserve
namespaces, the CRD, PVC and Secrets during recovery.
