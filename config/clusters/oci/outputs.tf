output "cluster_id" {
  description = "OKE cluster OCID."
  value       = oci_containerengine_cluster.this.id
}

output "cluster_name" {
  description = "OKE cluster name."
  value       = oci_containerengine_cluster.this.name
}

output "node_pool_ids" {
  description = "OKE node pool OCIDs keyed by node pool name."
  value = merge(
    { for name, pool in oci_containerengine_node_pool.fixed : name => pool.id },
    { for name, pool in oci_containerengine_node_pool.autoscaled : name => pool.id },
  )
}

output "selected_node_images" {
  description = "Node image OCIDs selected for each architecture."
  value       = local.selected_node_image_ids
}

output "gateway_public_ip_address" {
  description = "Reserved public IPv4 address for the OKE Envoy Gateway NLB."
  value       = oci_core_public_ip.gateway.ip_address
}

output "gateway_public_ip_id" {
  description = "OCID of the reserved public IPv4 address for the OKE Envoy Gateway NLB."
  value       = oci_core_public_ip.gateway.id
}

output "kubeconfig" {
  description = "Generated kubeconfig for the OKE cluster."
  value       = data.oci_containerengine_cluster_kube_config.this.content
  sensitive   = true
}
