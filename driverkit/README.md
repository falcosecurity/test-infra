# driverkit build grid

This folder contains the configuration files for the driverkit build grid.

## Usage

Just make is enough! :heart:

```console
make
```

### Available Make targets

- `specific_target`: build the filtered driver versions.
- `count_specific_target`: count the filtered driver versions.

#### Specific target

In case you want to build the drivers for just a distro or a specific kernel or both, use the `specific_target` make target:

```console
make -e TARGET_DISTRO=amazonlinux2 specific_target
```

##### Available filters

These are the available filters as environment variables:
- `TARGET_DISTRO`: a spefific Linux distribution.
- `TARGET_KERNEL`: a specific Linux version, in <kernel_version>.<major_version>.<minor_version> format.

Note: both are optional and cumulative. For instance you can filter a specific distro with a specific kernel version:

```console
make -e TARGET_DISTRO=debian -e TARGET_KERNEL=5.9.0 specific_target
```

## FAQ

Q: Falco doesn't find the kernel module/ eBPF probe for my OS, what do I do?
A: Go to the `config/` folder and add your kernel/OS combination there as a yaml file, then send a PR for everyone to profit!

Q: How do you publish new drivers?
A: If you have proper S3 permissions from terraform or prow, run

```console
make publish_s3
```

to publish the results after the build finishes.
