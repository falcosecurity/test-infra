resource "oci_identity_dynamic_group" "oke_nodes" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-nodes"
  description    = "Falco test-infra OKE worker node instances."
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
  freeform_tags  = local.tags
}

resource "oci_identity_policy" "oke_nodes" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  name           = "${var.cluster_name}-nodes"
  description    = "Instance-principal permissions for the cluster autoscaler, block-volume CSI, and cloud-controller-manager."
  freeform_tags  = local.tags

  statements = [
    # Cluster autoscaler: scale node pools and node instances.
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to manage cluster-node-pools in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to manage instance-family in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to use subnets in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to use vnics in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to use private-ips in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to use network-security-groups in compartment ${var.compartment_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to read virtual-network-family in compartment ${var.compartment_name}",
    # Block-volume CSI: provision and attach persistent volumes.
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to manage volume-family in compartment ${var.compartment_name}",
    # Cloud-controller-manager: provision LoadBalancer services.
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to manage load-balancers in compartment ${var.compartment_name}",
  ]
}
