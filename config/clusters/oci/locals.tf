locals {
  tags = {
    project   = "falco"
    component = "test-infra"
    managedBy = "terraform"
    scope     = "platform"
  }

  internet_cidr = "0.0.0.0/0"

  node_pools = {
    for name, pool in var.node_pools : name => merge(pool, {
      labels = merge(
        {
          Archtype    = pool.arch
          Application = pool.application
          nodepool    = name
        },
        pool.extra_labels
      )
    })
  }

  autoscaled_node_pools = {
    for name, pool in local.node_pools : name => pool if pool.autoscale
  }

  fixed_node_pools = {
    for name, pool in local.node_pools : name => pool if !pool.autoscale
  }

  # The OKE managed node pool resource has no native taints field
  # (oracle/terraform-provider-oci#1504). Taints are injected via node_metadata
  # in two places read by two different consumers, and BOTH are required:
  #  - user_data: a cloud-init that runs the default OKE bootstrap with
  #    --register-with-taints, so nodes are actually tainted when they join.
  #  - "kubelet-extra-args": the literal key the OKE cluster autoscaler parses to
  #    taint its scale-from-zero node template, matching pending pods before a
  #    node exists.
  pool_taint_args = {
    for name, pool in local.node_pools : name =>
    length(pool.taints) > 0 ? "--register-with-taints=${join(",", [for t in pool.taints : "${t.key}=${t.value}:${t.effect}"])}" : ""
  }

  pool_node_metadata = {
    for name, args in local.pool_taint_args : name =>
    args == "" ? {} : {
      user_data = base64encode(join("\n", [
        "#!/bin/bash",
        "curl --fail -H \"Authorization: Bearer Oracle\" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh",
        "bash /var/run/oke-init.sh --kubelet-extra-args \"${args}\"",
      ]))
      "kubelet-extra-args" = args
    }
  }
}
