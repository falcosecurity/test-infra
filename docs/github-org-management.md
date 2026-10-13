# Github organization management

The Falcosecurity project uses [peribolos](https://github.com/kubernetes/test-infra/blob/master/prow/cmd/peribolos/README.md) to manage the following aspects of the Github organization:
- Organization membership and org-wide rights
- Organization settings
- Teams and team members
- Repos and team repo rights

## How does this work?

Peribolos will sync the content of [`config/org.yaml`](/config/org.yaml) with our Github org settings in the following moments:
- each time that file is updated and merged onto `master`
- every 24 hours

## How do I add a new member to the organization?

Add an entry to the org's `members` array inside `config/org.yaml`, and then to each `members` array of the teams they are supposed to be part of:

```diff
org:
  falcosecurity:
  [...]
    members:
+     - john-doe
  [...]
    teams:
      somerepo-maintainers:
        description: Maintainers of somerepo
        [...]
        members:
+         - john-doe 
      someotherrepo-maintainers:
        description: Maintainers of someotherrepo
        [...]
        members:
+         - john-doe 
```

For active repositories, each repository team must include all `approvers` and
`reviewers` from its root and subdirectory `OWNERS` files. Do not include people
listed only as emeritus. The `core-maintainers` team must match the
[core maintainers list](https://github.com/falcosecurity/evolution/blob/main/MAINTAINERS.md#core-maintainers).

Within these teams, list organization owners (the org's `admins`) under
`maintainers` and everyone else under `members`. GitHub reports organization
owners as team maintainers, and Peribolos manages the teams. This team role is
separate from repository permissions and the roles in `OWNERS`. Purpose-specific
teams, such as `admins` and `machine_users`, are managed separately.

## What if I have further questions?

Please open an issue in this repo and someone from the Falco infra team will be happy to help!
