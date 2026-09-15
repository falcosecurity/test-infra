resource "oci_identity_policy" "cluster_autoscaler" {
  count = var.oke_cluster_ocid == null ? 0 : 1

  provider       = oci.home
  compartment_id = local.platform_compartment_id
  name           = "${var.cluster_name}-cluster-autoscaler"
  description    = "Node pool management for the OKE Cluster Autoscaler workload identity."
  freeform_tags  = local.platform_tags

  statements = [
    for permission in [
      "manage cluster-node-pools",
      "manage instance-family",
      "use subnets",
      "read virtual-network-family",
      "use vnics",
      "inspect compartments",
    ] :
    "Allow any-user to ${permission} in compartment ${var.compartment_name} where ALL {request.principal.type = 'workload', request.principal.namespace = 'kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${var.oke_cluster_ocid}'}"
  ]
}
