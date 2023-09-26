# driverkit build grid

This folder contains the configuration files for the driverkit build grid.

## Usage

The falcosecurity `dbg` heavily relies on [`dbg-go`](https://github.com/falcosecurity/dbg-go) tool.  
It is a golang tool used to interact with both driverkit configs, and s3 drivers.  

It allows to:
* generate configs (both a single config or auto generation from [kernel-crawler](https://github.com/falcosecurity/dbg-go) output)
* cleanup configs
* validate configs
* fetch stats about configs
* build configs, making use of driverkit as a library

Moreover, one can also:
* cleanup s3 drivers
* publish drivers to s3
* fetch stats about s3 drivers

The tool has a good README with some examples.  
Please make sure to download dbg-go binary for your architecture from the latest release: https://github.com/falcosecurity/dbg-go/releases.  

## FAQ

### Q: Where can I found the list all pre-compiled drivers?

A: Go to [https://download.falco.org/driver/site/index.html](https://download.falco.org/driver/site/index.html)

![drivers website screenshots](./drivers_website_screenshot.png)

### Q: Falco doesn't find the kernel module/ eBPF probe for my OS, what do I do?

A: You can generate and contribute configurations for your OS, as follows:

- [Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this [repository](https://github.com/falcosecurity/test-infra)
- From the root of the repository, run:
  ```shell
  dbg-go configs generate --target-distro=<TARGET_DISTRO> --target-kernelrelease=<TARGET_KERNELRELEASE> --target-kernelversion=<TARGET_KERNELRELEASE>
  ```
  > dbg-go help message is your friend to quickly check supported distros.

- Send a PR to this upstream repository, with the changes

The configurations are then consumed by [driverkit](https://github.com/falcosecurity/driverkit) in our [CI pipeline](../config/jobs).

You can find examples of configurations in this repository. The configuration paths are built as follows:

  `driverkit/config/<driver version>/<architecture>/<linux distribution>_<kernel release name>_<kernel build version>.yaml`.

You can also validate the configurations you generate with 
```shell
dbg-go configs validate --target-distro=<TARGET_DISTRO> --target-kernelrelease=<TARGET_KERNELRELEASE> --target-kernelversion=<TARGET_KERNELRELEASE>
```

It should be noted that the Driverkit Build Grid configurations are kept only for the last kernel-crawler's result, as the crawler represents the uniqe source of truth.  
Therefore, added configurations will be dropped on Driverkit Build Grid updates but published artifacts will not be cleaned up and will still remain available.

### Q: How do you publish new drivers?

A: If you have proper S3 permissions from Terraform or Prow, run

```console
dbg-go drivers publish
```

to publish the results after the build finishes.

### Q: How can I add support for prebuilt drivers for new distro?

A: Assuming that both kernel-crawler and driverkit already supports your distro, it is just a matter of:  
* adding the prow config for the new distro, under `test-infra/config/jobs/build-drivers/` folder; you can just copy eg: the `debian` one and then update any `debian` occurrence with your desired distro name. Please follow same name used by `driverkit` for the distro.  
* update the `SupportedDistros` map in `dbg-go` tool: https://github.com/falcosecurity/dbg-go/blob/main/pkg/root/distro.go
* ask for a new release of `dbg-go` tool
* bump `dbg-go` tool on both test-infra `update-dbg` and `build-drivers` images

If instead one between kernel-crawler or driverkit does not support the distro, you must first implement it there.  
For more informations, please see https://falco.org/blog/falco-prebuilt-drivers-new-distro/.
