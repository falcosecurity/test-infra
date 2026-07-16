data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

data "oci_containerengine_node_pool_option" "x86" {
  compartment_id        = var.compartment_ocid
  node_pool_k8s_version = var.nodepool_k8s_version
  node_pool_option_id   = "all"
  node_pool_os_arch     = "X86_64"
  node_pool_os_type     = "OL8"
}

data "oci_containerengine_node_pool_option" "arm" {
  compartment_id        = var.compartment_ocid
  node_pool_k8s_version = var.nodepool_k8s_version
  node_pool_option_id   = "all"
  node_pool_os_arch     = "AARCH64"
  node_pool_os_type     = "OL8"
}

locals {
  x86_node_images = [
    for source in data.oci_containerengine_node_pool_option.x86.sources :
    source if !strcontains(source.source_name, "GPU")
  ]

  arm_node_images = [
    for source in data.oci_containerengine_node_pool_option.arm.sources :
    source if !strcontains(source.source_name, "GPU")
  ]

  selected_node_image_ids = {
    x86 = coalesce(var.node_pool_image_ids.x86, local.x86_node_images[0].image_id)
    arm = coalesce(var.node_pool_image_ids.arm, local.arm_node_images[0].image_id)
  }
}

resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.control_plane_k8s_version
  name               = var.cluster_name
  type               = "ENHANCED_CLUSTER"
  vcn_id             = oci_core_vcn.this.id

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.kubernetes_api.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.service_lb.id]

    open_id_connect_discovery {
      is_open_id_connect_discovery_enabled = true
    }
  }

  freeform_tags = local.tags
}

resource "oci_containerengine_node_pool" "fixed" {
  for_each = local.fixed_node_pools

  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.nodepool_k8s_version
  name               = each.key
  node_shape         = each.value.shape

  node_shape_config {
    memory_in_gbs = each.value.memory_gbs
    ocpus         = each.value.ocpus
  }

  node_source_details {
    boot_volume_size_in_gbs = each.value.boot_volume_gbs
    image_id                = local.selected_node_image_ids[each.value.arch]
    source_type             = "image"
  }

  node_config_details {
    size = each.value.size

    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.this.availability_domains
      content {
        availability_domain = placement_configs.value.name
        subnet_id           = oci_core_subnet.node.id

        dynamic "preemptible_node_config" {
          for_each = each.value.preemptible ? [1] : []
          content {
            preemption_action {
              type                    = "TERMINATE"
              is_preserve_boot_volume = false
            }
          }
        }
      }
    }

    node_pool_pod_network_option_details {
      cni_type          = "OCI_VCN_IP_NATIVE"
      max_pods_per_node = each.value.max_pods_per_node
      pod_subnet_ids    = [oci_core_subnet.node.id]
      pod_nsg_ids       = []
    }
  }

  dynamic "initial_node_labels" {
    for_each = each.value.labels
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

  node_pool_cycling_details {
    is_node_cycling_enabled = false
  }

  node_metadata = local.pool_node_metadata[each.key]

  freeform_tags = local.tags

  lifecycle {
    precondition {
      condition     = var.allow_dynamic_node_images || var.node_pool_image_ids[each.value.arch] != null
      error_message = "Pin node_pool_image_ids for production applies, or explicitly set allow_dynamic_node_images=true for a controlled test."
    }
  }
}

resource "oci_containerengine_node_pool" "autoscaled" {
  for_each = local.autoscaled_node_pools

  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.nodepool_k8s_version
  name               = each.key
  node_shape         = each.value.shape

  node_shape_config {
    memory_in_gbs = each.value.memory_gbs
    ocpus         = each.value.ocpus
  }

  node_source_details {
    boot_volume_size_in_gbs = each.value.boot_volume_gbs
    image_id                = local.selected_node_image_ids[each.value.arch]
    source_type             = "image"
  }

  node_config_details {
    size = each.value.size

    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.this.availability_domains
      content {
        availability_domain = placement_configs.value.name
        subnet_id           = oci_core_subnet.node.id

        dynamic "preemptible_node_config" {
          for_each = each.value.preemptible ? [1] : []
          content {
            preemption_action {
              type                    = "TERMINATE"
              is_preserve_boot_volume = false
            }
          }
        }
      }
    }

    node_pool_pod_network_option_details {
      cni_type          = "OCI_VCN_IP_NATIVE"
      max_pods_per_node = each.value.max_pods_per_node
      pod_subnet_ids    = [oci_core_subnet.node.id]
      pod_nsg_ids       = []
    }
  }

  dynamic "initial_node_labels" {
    for_each = each.value.labels
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

  node_pool_cycling_details {
    is_node_cycling_enabled = false
  }

  node_metadata = local.pool_node_metadata[each.key]

  freeform_tags = local.tags

  lifecycle {
    ignore_changes = [
      node_config_details[0].size,
    ]

    precondition {
      condition     = var.allow_dynamic_node_images || var.node_pool_image_ids[each.value.arch] != null
      error_message = "Pin node_pool_image_ids for production applies, or explicitly set allow_dynamic_node_images=true for a controlled test."
    }
  }
}

data "oci_containerengine_cluster_kube_config" "this" {
  cluster_id = oci_containerengine_cluster.this.id
}
