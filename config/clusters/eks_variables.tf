variable "eks_default_worker_group_name" {
  default     = "default-worker-group"
  description = "The name of the default EKS worker group"
}

variable "eks_default_worker_group_instance_type" {
  default     = "m5.large"
  description = "The instance type of the default EKS worker group"
}

variable "eks_default_worker_group_asg_min_capacity" {
  default     = 3
  description = "The Autoscaling Group size of the default EKS worker group"
}

variable "eks_default_worker_group_asg_desired_capacity" {
  default     = 4
  description = "The Autoscaling Group size of the default EKS worker group"
}

variable "eks_default_worker_group_asg_max_capacity" {
  default     = 10
  description = "The Autoscaling Group size of the default EKS worker group"
}

variable "eks_default_worker_group_additional_userdata" {
  default     = 1
  description = "Uerdata to append to the default userdata of the default EKS worker group"
}


variable "eks_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::292999226676:user/jonah.jones"
      username = "jonah.jones"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/fontanalorenz@gmail.com"
      username = "fontanalorenz@gmail.com"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/leodidonato@gmail.com"
      username = "leodidonato@gmail.com"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/leonardo.grasso"
      username = "leonardo.grasso"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/massimiliano.giovagnoli"
      username = "massimiliano.giovagnoli"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/spencer.krum"
      username = "spencer.krum"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/thomas.labarussias"
      username = "thomas.labarussias"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/circleci"
      username = "circleci"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/michele@zuccala.com"
      username = "michele@zuccala.com"
      groups   = ["system:masters"]
    }
  ]
}
