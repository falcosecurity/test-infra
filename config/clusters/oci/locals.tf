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
}
