variable "eks_cluster_version" {
  default     = "1.21"
  description = "See https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html"
}

# Default Node Group.

variable "eks_default_worker_group_name" {
  default     = "default-worker-group"
  description = "The name of the default EKS worker group"
}

variable "eks_default_worker_group_instance_type" {
  default     = "m5.large"
  description = "The instance type of the default EKS worker group"
}

variable "eks_default_worker_group_asg_min_capacity" {
  default     = 1
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
  description = "Userdata to append to the default userdata of the default EKS worker group"
}

# Jobs on x86 Node Group.

variable "eks_jobs_worker_group_name" {
  default     = "jobs-worker-group"
  description = "The name of the jobs EKS worker group"
}

variable "eks_jobs_worker_group_instance_type" {
  default     = "m5.large"
  description = "The instance type of the jobs EKS worker group"
}

variable "eks_jobs_worker_group_asg_min_capacity" {
  default     = 1
  description = "The Autoscaling Group size of the jobs EKS worker group"
}

variable "eks_jobs_worker_group_asg_desired_capacity" {
  default     = 4
  description = "The Autoscaling Group size of the jobs EKS worker group"
}

variable "eks_jobs_worker_group_asg_max_capacity" {
  default     = 10
  description = "The Autoscaling Group size of the jobs EKS worker group"
}

variable "eks_jobs_worker_group_additional_userdata" {
  default     = 1
  description = "Userdata to append to the default userdata of the jobs EKS worker group"
}

# Jobs on ARM64 Node Group.

variable "eks_jobs_arm_worker_group_name" {
  default     = "jobs-arm-worker-group"
  description = "The name of the jobs EKS worker group"
}

variable "eks_jobs_arm_worker_group_instance_type" {
  default     = "m6g.large"
  description = "The instance type of the jobs ARM EKS worker group"
}

variable "eks_jobs_arm_worker_group_asg_min_capacity" {
  default     = 1
  description = "The Autoscaling Group size of the ARM EKS worker group"
}

variable "eks_jobs_arm_worker_group_asg_desired_capacity" {
  default     = 1
  description = "The Autoscaling Group size of the ARM EKS worker group"
}

variable "eks_jobs_arm_worker_group_asg_max_capacity" {
  default     = 3
  description = "The Autoscaling Group size of the ARM EKS worker group"
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
      userarn  = "arn:aws:iam::292999226676:user/michele@zuccala.com"
      username = "michele@zuccala.com"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/federico.dipierro"
      username = "federico.dipierro"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::292999226676:user/luca.guerra"
      username = "luca.guerra"
      groups   = ["system:masters"]
    }
  ]
}
variable "eks_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn = string
    username = string
    groups = list(string)
  }))

  default = [
    {
      rolearn  = "arn:aws:iam::292999226676:role/github_actions-test-infra-cluster"
      username = "githubactions-test-infra-cluster"
      groups   = ["system:masters"]
    },
  ]
}
