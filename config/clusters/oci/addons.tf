resource "oci_containerengine_addon" "cluster_autoscaler" {
  count = length(local.autoscaled_node_pools) > 0 ? 1 : 0

  addon_name                       = "ClusterAutoscaler"
  cluster_id                       = oci_containerengine_cluster.this.id
  remove_addon_resources_on_delete = true

  configurations {
    key   = "authType"
    value = "instance"
  }

  configurations {
    key = "nodes"
    value = join(",", [
      for name, pool in local.autoscaled_node_pools :
      "${pool.autoscaler_min}:${pool.autoscaler_max}:${oci_containerengine_node_pool.autoscaled[name].id}"
    ])
  }
}
