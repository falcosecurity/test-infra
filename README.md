# test-infra

[![Falco Infra Repository](https://github.com/falcosecurity/evolution/blob/main/repos/badges/falco-infra-blue.svg)](https://github.com/falcosecurity/evolution/blob/main/REPOSITORIES.md#infra-scope) [![Stable](https://img.shields.io/badge/status-stable-brightgreen?style=for-the-badge)](https://github.com/falcosecurity/evolution/blob/main/REPOSITORIES.md#stable) [![License](https://img.shields.io/github/license/falcosecurity/test-infra?style=for-the-badge)](./LICENSE)

GitHub Workflow & Testing Infrastructure

## Cloud configuration

Infrastructure is separated by area and cloud:

| Area | AWS | OCI |
| --- | --- | --- |
| Terraform | [Cluster](config/clusters/aws/) | [Cluster](config/clusters/oci/) |
| Applications | [Applications](config/applications/aws/) | [Applications](config/applications/oci/) |
| Prow | [Configuration](config/prow/aws/) | [Configuration](config/prow/oci/) |
| Prow jobs | [Archived jobs](config/backup/aws/jobs/) | [Active jobs](config/jobs/oci/) |

AWS and OCI have independent Prow versions, configuration, and node scheduling.
The [OCI bootstrap](config/clusters/oci/bootstrap/) is managed and validated
locally, outside CI.

## DBG

DBG stands for Drivers Build Grid.

It's a tool that we created to prebuilt a set of Falco drivers (both kernel module and eBPF probe) for various target distro and kernel releases, by using [driverkit](https://github.com/falcosecurity/driverkit).

You can find more about it [here](/driverkit).

### Contribute

You can contribute in order to distribute prebuilt Falco drivers for new Linux kernel releases by following [this guide](./driverkit/README.md#q-falco-doesnt-find-the-kernel-module-ebpf-probe-for-my-os-what-do-i-do).

## Prow

[Prow](https://github.com/kubernetes/test-infra/tree/master/prow) is a CI/CD system running on Kubernetes.

This directory contains the resources composing the Falco's workflow & testing infrastructure. 

Are you looking for Deck to check the merge queue and prow jobs?

- https://prow.falco.org

### Adding a Job on Prow

Add job definitions to [the OCI catalog](config/jobs/oci/) and include them in
its [Kustomization](config/jobs/oci/kustomization.yaml).

- **Presubmits** run against pull requests: [DBG validation](config/jobs/oci/build-drivers/validate-dbg.yaml).
- **Postsubmits** run after changes are pushed: [driver builds](config/jobs/oci/build-drivers/build-new-amazonlinux.yaml).
- **Periodics** run on a schedule: [DBG updates](config/jobs/oci/update-dbg/update-dbg.yaml).

Use the workload's existing service account, resource requests, node selectors
and tolerations as references. The AWS job definitions are archived and are not
part of the active catalog.
