# GitHub Workflow & Testing Infrastructure

## Prow

[Prow](https://github.com/kubernetes/test-infra/tree/master/prow) is a CI/CD system running on Kubernetes.

This directory contains the resources composing the Falco's workflow & testing infrastructure.

### Components

Listing the deployments we are currently using.

#### Deck

> UI for prow jobs.

#### Sinker

> Clean up stale prow jobs.

#### Hook

> Handle GitHub events dispatching them to plugins.

#### Horologium

> Starts periodic jobs.

#### Plank

> Star prow jobs

---