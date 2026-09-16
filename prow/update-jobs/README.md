# Config Uploader

## Overview

This utility uploads Prow configuration to existing ConfigMaps. It is run
manually and replaces each selected ConfigMap's contents.

> **NOTE:** Each ConfigMap selected for upload must already exist on the cluster.

### Flags

See the list of available flags:

| Name                      | Required | Description                                                                                          |
| :------------------------ | :------: | :--------------------------------------------------------------------------------------------------- |
| **--kubeconfig**          |    No    | Kubeconfig path; when omitted, the tool uses in-cluster ServiceAccount authentication.              |
| **--config-path**         |    No    | The path to the `config.yaml` file. Set it to upload the Prow configuration to a cluster.            |
| **--jobs-config-path**    |    No    | The path to the directory with job configurations. Set it to upload job configurations to a cluster. |
| **--plugins-config-path** |    No    | The path to the `plugins.yaml` file. Set it to upload plugin configurations to a cluster.             |
