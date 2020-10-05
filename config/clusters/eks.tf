module "eks" {
  source           = "terraform-aws-modules/eks/aws"
  cluster_name     = local.cluster_name
  cluster_version  = "1.17"
  subnets          = module.vpc.private_subnets
  write_kubeconfig = true
  map_users        = var.eks_users
  enable_irsa      = true

  tags = {
    Environment = "training"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }

  #Managed Node Group
  node_groups = {
    falco-ng = {
      desired_capacity = var.eks_default_worker_group_asg_desired_capacity
      max_capacity     = var.eks_default_worker_group_asg_max_capacity
      min_capacity     = var.eks_default_worker_group_asg_min_capacity
      instance_type    = var.eks_default_worker_group_instance_type
      k8s_labels = {
        Environment = "training"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      additional_tags = {
        ExtraTag = "falco"
      }
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
