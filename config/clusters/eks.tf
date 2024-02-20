module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.1.0"

  cluster_name              = local.cluster_name
  cluster_version           = var.eks_cluster_version
  subnets                   = module.vpc.private_subnets
  write_kubeconfig          = true
  map_users                 = var.eks_users
  map_roles                 = var.eks_roles
  enable_irsa               = true
  cluster_enabled_log_types = ["audit"]

  tags = {
    Environment = "training"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  workers_additional_policies = [
    aws_iam_policy.ebs_controller_policy.arn,
    aws_iam_policy.cluster_autoscaler_policy.arn
  ]

  node_groups_defaults = {
    disk_size = 50
  }

  #Managed Node Group
  node_groups = {
    default = {
      name             = var.eks_default_worker_group_name
      desired_capacity = var.eks_default_worker_group_asg_desired_capacity
      max_capacity     = var.eks_default_worker_group_asg_max_capacity
      min_capacity     = var.eks_default_worker_group_asg_min_capacity

      instance_types     = [var.eks_default_worker_group_instance_type]
      ami_type           = "AL2_x86_64"
      version            = var.eks_cluster_version
      kubelet_extra_args = "--kube-reserved=emephemeral-storage=30Gi"

      k8s_labels = {
        Archtype    = "x86"
        Application = "prow"
        Environment = "training"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
    }

    jobs = {
      name             = var.eks_jobs_worker_group_name
      desired_capacity = var.eks_jobs_worker_group_asg_desired_capacity
      max_capacity     = var.eks_jobs_worker_group_asg_max_capacity
      min_capacity     = var.eks_jobs_worker_group_asg_min_capacity

      # This Node Group is available in a Single Availability Zone.
      # This should avoid AutoScaling to conflict with cluster-autoscaler
      # during intervention after AZ-rebalance.
      # Read more here: https://github.com/kubernetes/autoscaler/issues/3693
      # This is needed to guarantee QoS for long-running build jobs.
      subnets = [module.vpc.private_subnets[0]]
      taints  = [local.single_az_nodegroup_taint]

      instance_types     = [var.eks_jobs_worker_group_instance_type]
      kubelet_extra_args = "--kube-reserved=emephemeral-storage=30Gi"
      ami_type           = "AL2_x86_64"
      version            = var.eks_cluster_version

      k8s_labels = {
        Archtype    = "x86"
        Application = "jobs"
        Environment = "training"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
    }

    jobs_arm = {
      name             = var.eks_jobs_arm_worker_group_name
      desired_capacity = var.eks_jobs_arm_worker_group_asg_desired_capacity
      max_capacity     = var.eks_jobs_arm_worker_group_asg_max_capacity
      min_capacity     = var.eks_jobs_arm_worker_group_asg_min_capacity

      # This Node Group is available in a Single Availability Zone.
      # This should avoid AutoScaling to conflict with cluster-autoscaler
      # during intervention after AZ-rebalance.
      # Read more here: https://github.com/kubernetes/autoscaler/issues/3693
      # This is needed to guarantee QoS for long-running build jobs.
      # TODO: refactor the subnets assignment.
      subnets = length(var.vpc_private_subnets_cidr_blocks) > 1 ? [module.vpc.private_subnets[1]] : [module.vpc.private_subnets[0]]

      instance_types = [var.eks_jobs_arm_worker_group_instance_type]
      ami_type       = "AL2_ARM_64"
      taints = [
        local.arm_nodegroup_taint,
        local.single_az_nodegroup_taint,
      ]

      version            = var.eks_cluster_version
      kubelet_extra_args = "--kube-reserved=emephemeral-storage=30Gi"

      k8s_labels = {
        Archtype    = "arm"
        Application = "jobs"
        Environment = "training"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }

      additional_tags = {
        ExtraTag = "arm"
      }
    }
  }
}

locals {
  arm_nodegroup_taint = {
    key    = "Archtype"
    value  = "arm"
    effect = "NO_SCHEDULE",
  }

  single_az_nodegroup_taint = {
    key    = "Availability"
    value  = "SingleAZ"
    effect = "NO_SCHEDULE"
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
