# driverkit build grid

This folder contains the configuration files for the driverkit build grid.

## Usage

Just make is enough! :heart:

```console
make
```

### Available make targets

- `all`: build all the Falco drivers (all the versions), for every supported distro, and every supported kernel release
- `specific_target`: build the filtered driver versions
- `clean`: remove everything in the `output/` directory (except it, and its `.gitignore` file)
- `publish`: publish all the built Falco drivers (those existing in the `output/` directory) to bintray
- `publish_<driver_version>`: publish all the built Falco drivers to bintray filtering by the Falco driver version (those existing in the `output/<driver_version>` directory)
- `publish_s3`: publish all the built Falco drivers (those existing in the `output/` directory) to S3
- `publish_s3_<driver_version>`: publish all the built Falco drivers to S3 filtering by the Falco driver version (those existing in the `output/<driver_version>` directory)
- `cleanup`: delete from bintray the driver version no more supported (those present on bintray but not in the `config/` directory)
- `cleanup_s3`: delete from S3 the driver version no more supported (those present on S3 but not in the `config/` directory)
- `stats`:

#### Specific target

In case you want to build the Falco drivers (all the available versions) for just a distro or a specific kernel or both, use the `specific_target` make target:

```console
make -e TARGET_DISTRO=amazonlinux2 specific_target
```

##### Available filters

These are the available filters as environment variables:

- `TARGET_VERSION`: a specific Falco driver version
- `TARGET_DISTRO`: a spefific Linux distribution
- `TARGET_KERNEL`: a specific Linux version
  - in <kernel_version>.<major_version>.<minor_version> format
  - in <kernel_version>.<major_version>.* format
  - in <kernel_version>.* format

Notice all the filters are optional.

You can also filter a specific distro with a specific kernel version:

```console
make -e TARGET_DISTRO="debian" -e TARGET_KERNEL="5.9.0" specific_target
```

Or, you can ask it to make all the Falco drivers for debian 5.x kernels.

```console
make -e TARGET_DISTRO="debian" -e TARGET_KERNEL="5.x" specific_target
```

In case you're only interested in a precise Falco driver version, you can filter by it too:

```console
make -e TARGET_VERSION="2aa88" -e TARGET_DISTRO="debian" -e TARGET_KERNEL="4.9.*" specific_target
```

## FAQ

Q: Falco doesn't find the kernel module/ eBPF probe for my OS, what do I do?
A: Go to the `config/` folder and add your kernel/OS combination there as a YAML file, then send a PR for everyone to profit!

Q: How do you publish new drivers?
A: If you have proper S3 permissions from Terraform or Prow, run

```console
make publish_s3
```

to publish the results after the build finishes.
