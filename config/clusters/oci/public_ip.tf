resource "oci_core_public_ip" "gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-gateway-public-ip"
  lifetime       = "RESERVED"
  freeform_tags  = local.tags

  lifecycle {
    # The Kubernetes NLB controller owns the dynamic private-IP attachment.
    ignore_changes = [private_ip_id]

    # DNS and the public Gateway depend on this address remaining stable.
    prevent_destroy = true
  }
}
