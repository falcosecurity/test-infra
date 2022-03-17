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

This is done by adding an entry to the org's `members` array inside `config/org.yaml`, and then to each `members` array of the teams he is supposed to be part of:

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

## What if I have further questions?

Please open an issue in this repo and someone from the Falco infra team will be happy to help!
