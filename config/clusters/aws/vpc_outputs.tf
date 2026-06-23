output "vpc_id" {
  description = "The VPC id where the cluster is provisioned to"
  value       = module.vpc.vpc_id
}