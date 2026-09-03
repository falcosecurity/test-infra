locals {
  # Cluster add-ons run on the on-demand prow control-plane pool; every worker pool is tainted.
  addon_node_selector = jsonencode({ Application = "platform" })
  addon_tolerations = jsonencode([{
    key      = "dedicated.falco.org/platform"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }])
}

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

  configurations {
    key   = "nodeSelectors"
    value = local.addon_node_selector
  }

  configurations {
    key   = "tolerations"
    value = local.addon_tolerations
  }
}

resource "oci_containerengine_addon" "cert_manager" {
  addon_name                       = "CertManager"
  cluster_id                       = oci_containerengine_cluster.this.id
  remove_addon_resources_on_delete = true

  depends_on = [oci_containerengine_addon.cluster_autoscaler]

  configurations {
    key   = "numOfReplicas"
    value = "1"
  }

  configurations {
    key   = "nodeSelectors"
    value = local.addon_node_selector
  }

  configurations {
    key   = "tolerations"
    value = local.addon_tolerations
  }
}

resource "oci_containerengine_addon" "metrics_server" {
  addon_name                       = "KubernetesMetricsServer"
  cluster_id                       = oci_containerengine_cluster.this.id
  remove_addon_resources_on_delete = true

  depends_on = [oci_containerengine_addon.cert_manager]

  configurations {
    key   = "numOfReplicas"
    value = "1"
  }

  configurations {
    key   = "nodeSelectors"
    value = local.addon_node_selector
  }

  configurations {
    key   = "tolerations"
    value = local.addon_tolerations
  }
}

resource "oci_containerengine_addon" "native_ingress_controller" {
  addon_name                       = "NativeIngressController"
  cluster_id                       = oci_containerengine_cluster.this.id
  remove_addon_resources_on_delete = true

  depends_on = [
    oci_containerengine_addon.metrics_server,
    oci_identity_policy.oke_nodes,
    oci_identity_policy.oke_nodes_tenancy,
  ]

  configurations {
    key   = "compartmentId"
    value = var.compartment_ocid
  }

  configurations {
    key   = "loadBalancerSubnetId"
    value = oci_core_subnet.service_lb.id
  }

  configurations {
    key   = "authType"
    value = "instance"
  }

  configurations {
    key   = "numOfReplicas"
    value = "1"
  }

  configurations {
    key   = "nodeSelectors"
    value = local.addon_node_selector
  }

  configurations {
    key   = "tolerations"
    value = local.addon_tolerations
  }
}

resource "oci_containerengine_addon" "core_dns" {
  addon_name                       = "CoreDNS"
  cluster_id                       = oci_containerengine_cluster.this.id
  remove_addon_resources_on_delete = false
  override_existing                = true

  depends_on = [oci_containerengine_addon.native_ingress_controller]

  configurations {
    key   = "nodesPerReplica"
    value = "16"
  }

  configurations {
    key   = "minReplica"
    value = "3"
  }

  configurations {
    key   = "customizeCoreDNSConfigMap"
    value = "false"
  }

  configurations {
    key = "topologySpreadConstraints"
    value = jsonencode([{
      maxSkew           = 1
      topologyKey       = "kubernetes.io/hostname"
      whenUnsatisfiable = "ScheduleAnyway"
      labelSelector     = { matchLabels = { "k8s-app" = "kube-dns" } }
    }])
  }

  configurations {
    key   = "nodeSelectors"
    value = local.addon_node_selector
  }

  configurations {
    key   = "tolerations"
    value = local.addon_tolerations
  }
}
