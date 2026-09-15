# OCI applications

[deploy_argocd_oci.sh](../../../tools/deploy_argocd_oci.sh) installs Argo CD and
the root Application on OKE. It uses an isolated kubeconfig and verifies the
cluster endpoint before applying resources. Authenticate with the intended OCI
profile before running it.

## Grafana

Before syncing [kube-prometheus-stack](kube-stack-prometheus.yaml), provision the
`grafana-admin` Secret in the `monitoring` namespace through the credential
management process. It must contain `admin-user` and `admin-password`, with a
strong, unique password. The chart references this external Secret and does not
generate administrator credentials. Keep credential values out of Git and logs.

When adopting an existing chart-managed credential, preserve the old Secret until
the rollout succeeds and ensure it is not pruned while still referenced. Changing
a password only through the UI does not update the external Secret.

Grafana provides anonymous Viewer access. Its local data is ephemeral; dashboards
are provisioned from configuration. Back up any UI-managed content before
replacing the pod or upgrading Grafana.
