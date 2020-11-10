# Config Uploader

## Overview

We use a custom Go Config-Uploader to update job-config here from all the files.

go run cmd/configuploader/main.go --kubeconfig $HOME/.kube/config --plugin-config-path {pathToPluginsYaml}

> **NOTE:** Config Uploader expects that the `config`, `plugins`, and `job-config` ConfigMaps are present on the cluster.

### Flags

See the list of available flags:

| Name                      | Required | Description                                                                                          |
| :------------------------ | :------: | :--------------------------------------------------------------------------------------------------- |
| **--kubeconfig**          |   Yes    | The path to the `kubeconfig` file, needed to connect to a cluster.                                   |
| **--config-path**         |    No    | The path to the `config.yaml` file. Set it to upload the Prow configuration to a cluster.            |
| **--jobs-config-path**    |    No    | The path to the directory with job configurations. Set it to upload job configurations to a cluster. |
| **--plugins-config-path** |    No    | The path to the `plugins.yaml` file. Set it to upload plugin configurations to a cluster.             |