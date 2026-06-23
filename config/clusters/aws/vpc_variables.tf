variable "vpc_cidr_block" {
  default     = "10.0.0.0/16"
  description = "The CIDR block of the main VPC"
}

variable "vpc_public_subnets_cidr_blocks" {
  default     = []
  description = "The CIDR blocks of the main VPC's public subnets"
}

variable "vpc_private_subnets_cidr_blocks" {
  default     = []
  description = "The CIDR blocks of the main VPC's public subnets"
}

variable "vpc_enable_nat_gateway" {
  default     = true
  description = "A boolean flag to provision NAT Gateways for each of your private networks"
}

variable "vpc_single_nat_gateway" {
  default     = true
  description = "A boolean flag to provision a single shared NAT Gateway across all of your private networks"
}

variable "vpc_enable_dns_hostnames" {
  default     = true
  description = "A boolean flag to enable/disable DNS hostnames in the main VPC"
}