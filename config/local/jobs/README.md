# ProwJobs

Make sure prow has been [deployed] correctly:

* The `horologium` component schedules periodic jobs.
* The `hook` component schedules presubmit and postsubmit jobs, ensuring the repo:
  - enabled `trigger` in [`plugins.yaml`]
  - sends GitHub webhooks to prow.
* The `prow-controller-manager` component schedules the pod requested by a prowjob.
* The `crier` component reports status back to github.

## How to configure new jobs

To configure a new job you'll need to add a job into [jobs](/config/jobs).

```
config/jobs/
├── OWNERS
├── README.md
└── update-jobs
    └── update-jobs.yaml
```
If we wanted to add a new job to test a driver, we would add a new folder called `test-driver` and a job definition in yaml in the corresponding folder.

```
config/jobs/
├── OWNERS
├── README.md
├── test-driver
│   └── test-driver.yaml
└── update-jobs
    └── update-jobs.yaml
```

On a PR the `update-jobs` Presubmit job will run, and allow testing of the new proposed job.


Prow requires you to have a basic understanding of kubernetes, such
that you can define pods in yaml.  Please see kubernetes documentation
for help here, for example the [Pod overview] and [PodSpec api
reference].

Periodic config looks like so:

```yaml
periodics:
- name: update-jobs-periodic        # Names need not be unique, but must match the regex ^[A-Za-z0-9-._]+$
  decorate: true        # Enable Pod Utility decoration. (see below)
  extra_refs: # Pod utility Clone Ref will clone the corresponding repository into the workspace before the test using an init container.
  #Clone Path == /home/prow/go/src/github.com/repo_org/repo_name
  - org: falcosecurity
      repo: test-infra
      base_ref: <PULL_REQUEST_BRANCH_NAME>
  interval: 1h          # Anything that can be parsed by time.ParseDuration.
  # Alternatively use a cron instead of an interval, for example:
  # cron: "05 15 * * 1-5"  # Run at 7:05 PST (15:05 UTC) every M-F
  agent: kubernetes
  spec:     # Valid Kubernetes PodSpec.
    containers:
    - command:
      - /workspace/update-jobs.sh
      env:  #This is required if using the AWSCLI from the job script
      - name: AWS_REGION
        value: eu-west-1            
```

Postsubmit config looks like so:

```yaml
postsubmits:
  org/repo:
  - name: bar-job         # As for periodics.
    decorate: true        # As for periodics.
    spec: {}              # As for periodics.
    max_concurrency: 10   # Run no more than this number concurrently.
    branches:             # Regexps, only run against these branches.
    - ^master$
    skip_branches:        # Regexps, do not run against these branches.
    - ^release-.*$
```

Postsubmits are run when a push event happens on a repo, hence they are
configured per-repo. If no `branches` are specified, then they will run against
every branch.

Presubmit config looks like so:

```yaml
presubmits:
  - name: update-jobs
    decorate: true
    path_alias: github.com/falcosecurity/test-infra #Tell Github to clone this repo 
    #Clone Path == /home/prow/go/src/github.com/repo_org/repo_name
    skip_report: false # Whether to skip setting a status on GitHub, use to show success/failure in github.
    agent: kubernetes
    run_if_changed: '^config/jobs/' #Trigger if PR changes files in this path
    branches: 
      - ^master$ #Any branch besides master
    spec:
      containers:
      - command:
        - /workspace/update-jobs.sh
        env:
        - name: AWS_REGION
          value: eu-west-1 
```

If you only want to run tests when specific files are touched, you can use
`run_if_changed`. A useful pattern when adding new jobs is to start with
`always_run` set to false and `skip_report` set to true. Test it out a few
times by manually triggering, then switch `always_run` to true. Watch for a
couple days, then switch `skip_report` to false.

The `trigger` is a regexp that matches the `rerun_command`. Users will be told
to input the `rerun_command` when they want to rerun the job. Actually, anything
that matches `trigger` will suffice. This is useful if you want to make one
command that reruns all jobs. If unspecified, the default configuration makes
`/test <job-name>` trigger the job. so `/test update-jobs`
