# AWS Prow jobs

This directory contains the AWS Prow job catalog.

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
