# driverkit build grid

This folder contains the configuration files for the driverkit build grid.

## Usage

Just make is enough! :heart:

```console
make
```

In case you want to build the drivers for just a distro, use the following make target as below.

```console
make -e TARGET_DISTRO=amazonlinux2 specific_target
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
