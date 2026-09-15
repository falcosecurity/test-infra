# AWS Prow jobs

This directory contains the AWS Prow job catalog. The
[config-updater mappings](../../prow/aws/plugins.yaml) publish the catalog to
Prow, and [check-prow-config](check-prow-config/check-prow-config.yaml) validates
the core, plugin and job configuration.

## Job types

- Presubmits run against pull requests. See
  [check-prow-config](check-prow-config/check-prow-config.yaml).
- Postsubmits run after changes are pushed. See
  [image publishing](build-prow-images/publish-images.yaml).
- Periodics run on a schedule. See
  [the EKS upgrade reminder](recurring-ghissues/prow-eks-upgrade.yaml).

## Adding a job

Add a YAML definition in a subdirectory for the workload. Configure its
container image, command, resource requirements and scheduling constraints for
the AWS cluster. Use the existing definitions above as references for the job
type's structure.

The [local testing guide](../../../docs/local-testing.md) describes how to run
a job during development. Repository CI validates the submitted configuration.

## Configuration updates

Prow's `config-updater` manages the job ConfigMap using the committed AWS paths.
The [deployment script](../../../tools/deploy_prow.sh) creates missing
ConfigMaps without overwriting existing configuration.

The [manual uploader](../../../prow/update-jobs/README.md) replaces ConfigMap
contents and must not run concurrently with automatic configuration updates.
