app_name                                      = "test-infra"
app_namespace                                 = "falco"
app_stage                                     = "prow"
region                                        = "eu-west-1"
vpc_private_subnets_cidr_blocks               = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
vpc_public_subnets_cidr_blocks                = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
vpc_cidr_block                                = "10.0.0.0/16"
eks_default_worker_group_name                 = "prow-worker-group"
eks_default_worker_group_instance_type        = "m5.large"
eks_default_worker_group_asg_desired_capacity = 3

# Max capacities of the EKS Node Groups / AutoScaling Groups.
eks_default_worker_group_asg_max_capacity  = 10
eks_jobs_worker_group_asg_max_capacity     = 20
eks_jobs_arm_worker_group_asg_max_capacity = 20

eks_roles = [
  {
    rolearn  = "arn:aws:iam::292999226676:role/github_actions-test-infra-cluster"
    username = "githubactions-test-infra-cluster"
    groups   = ["system:masters"]
  },
  {
    rolearn  = "arn:aws:iam::292999226676:role/github_actions-test-infra-reader"
    username = "githubactions-test-infra-reader"
    groups   = ["aws-config-readers"]
  },
]

