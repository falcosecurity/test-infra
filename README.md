# GitHub Workflow & Testing Infrastructure

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

Falco is the first Public Prow instance running 100% on AWS infrastructure. This means there are slight differences when it comes to adding jobs to Falco's Prow.


### Job Types

There are three types of prow jobs:

- **Presubmits** run against code in PRs

- **Postsubmits** run after merging code

- **Periodics** run on a periodic basis



### Create a Presubmits job that run's tests on PR's.

1. We add a file at `config/jobs/build-drivers/build-drivers.yaml`

2. 
```yaml
 presubmits:
  falcosecurity/test-infra: #Name of the org/repo
  - name: build-drivers-amazonlinux-presubmit
    decorate: true
    skip_report: false
    agent: kubernetes
    branches:
      - ^master$
    spec:
      containers:
      - command:
        - /workspace/build-drivers.sh
        - amazonlinux
        env:
        - name: AWS_REGION
          value: eu-west-1
        image: 292999226676.dkr.ecr.eu-west-1.amazonaws.com/test-infra/build-drivers:latest
        imagePullPolicy: Always
        securityContext:
          privileged: true
```

A few things to call out.

- branches: `^master$`  is telling prow to run this on any branch but Master
- command: `/workspace/build-drivers.sh` this is telling the docker container to run as the test script. See the [script](images/build-drivers/build-drivers.sh)
- privileged: `true` This is required when using Docker in Docker, or Docker builds.
- decorate: `true` is adding pod utilities to the prow jobs as an init container. This pulls in source code for the job, to leverage scripts and files in the pull request. 


3. Once we add this job, we're going to create our PR, and test this via Github / commands.
