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

  # Managed node pools have no taints field; taints are injected via node_metadata.
  # Both keys are required: user_data taints nodes at boot via the OKE bootstrap
  # (--register-with-taints); kubelet-extra-args lets the autoscaler taint its
  # scale-from-zero template.
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
