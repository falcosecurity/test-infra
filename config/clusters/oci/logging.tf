# Log group for OKE control-plane logs.
resource "oci_logging_log_group" "oke_control_plane" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-control-plane"
  description    = "OKE control-plane service logs."
  freeform_tags  = local.tags
}
