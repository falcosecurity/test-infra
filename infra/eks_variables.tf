variable "eks_default_worker_group_name" {
  default     = "default-worker-group"
  description = "The name of the default EKS worker group"
}

variable "eks_default_worker_group_instance_type" {
  default     = "t2.micro"
  description = "The instance type of the default EKS worker group"
}

variable "eks_default_worker_group_asg_desired_capacity" {
  default     = 1
  description = "The Autoscaling Group size of the default EKS worker group"
}

variable "eks_default_worker_group_additional_userdata" {
  default     = 1
  description = "Uerdata to append to the default userdata of the default EKS worker group"
}

