## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.2 |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.3.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | > 3.45.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | > 2.0.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | > 1.2 |
| <a name="requirement_null"></a> [null](#requirement\_null) | > 2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | > 2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.50.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_driver_kit_s3_role"></a> [driver\_kit\_s3\_role](#module\_driver\_kit\_s3\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 4.1.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 17.1.0 |
| <a name="module_falco_dev_s3_role"></a> [falco\_dev\_s3\_role](#module\_falco\_dev\_s3\_role) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-role | 5.10.0 |
| <a name="module_falco_ecr_role"></a> [falco\_ecr\_role](#module\_falco\_ecr\_role) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-role | 5.10.0 |
| <a name="module_falco_s3_role"></a> [falco\_s3\_role](#module\_falco\_s3\_role) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-role | 5.10.0 |
| <a name="module_falcosidekick_ecr_role"></a> [falcosidekick\_ecr\_role](#module\_falcosidekick\_ecr\_role) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-role | 5.10.0 |
| <a name="module_iam_assumable_role_admin"></a> [iam\_assumable\_role\_admin](#module\_iam\_assumable\_role\_admin) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 4.1.0 |
| <a name="module_iam_github_oidc_provider"></a> [iam\_github\_oidc\_provider](#module\_iam\_github\_oidc\_provider) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider | 5.10.0 |
| <a name="module_label"></a> [label](#module\_label) | git::https://github.com/cloudposse/terraform-terraform-label.git | 0.8.0 |
| <a name="module_load_balancer_controller"></a> [load\_balancer\_controller](#module\_load\_balancer\_controller) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 4.1.0 |
| <a name="module_plugins_s3_role"></a> [plugins\_s3\_role](#module\_plugins\_s3\_role) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-role | 5.10.0 |
| <a name="module_rules_s3_role"></a> [rules\_s3\_role](#module\_rules\_s3\_role) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-role | 5.10.0 |
| <a name="module_test-infra_s3_role"></a> [test-infra\_s3\_role](#module\_test-infra\_s3\_role) | terraform-aws-modules/iam/aws//modules/iam-github-oidc-role | 5.10.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.18.1 |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.deck](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate.monitor_prow](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_dynamodb_table.falco-test-infra-state-lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_ecr_repository.build_drivers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.build_plugins](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.docker_dind](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.golang](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.update_dbg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.update_deployment_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.update_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.update_rules_index](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.build_drivers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_ecr_repository_policy.build_plugins](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_ecr_repository_policy.docker_dind](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_ecr_repository_policy.golang](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_ecr_repository_policy.update_dbg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_ecr_repository_policy.update_deployment_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_ecr_repository_policy.update_jobs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_iam_policy.cluster_autoscaler_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.driverkit_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ebs_controller_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.falco_dev_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.falco_ecr_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.falco_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.falcosidekick_ecr_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.loadbalancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.plugins_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.rules_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.test-infra_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_kms_key.falco-test-infra-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.prow_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.falco-test-infra-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.prow_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.falco-test-infra-state_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_acl.prow_storage_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.prow_storage_lifecycle_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.falco-test-infra-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.prow_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.falco-test-infra-state_server_side_encryption_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.prow_storage_server_side_encryption_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.falco-test-infra-state_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.prow_storage_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_security_group.all_worker_mgmt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.worker_group_mgmt_one](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_canonical_user_id.current_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.cluster_autoscaler_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.driverkit_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ebs_controller_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecr_standard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.falco-test-infra-state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.falco_dev_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.falco_ecr_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.falco_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.falcosidekick_ecr_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.loadbalancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.plugins_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.prow_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.rules_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.test-infra_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | n/a | `any` | n/a | yes |
| <a name="input_app_namespace"></a> [app\_namespace](#input\_app\_namespace) | n/a | `any` | n/a | yes |
| <a name="input_app_stage"></a> [app\_stage](#input\_app\_stage) | n/a | `any` | n/a | yes |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | See https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html | `string` | `"1.20"` | no |
| <a name="input_eks_default_worker_group_additional_userdata"></a> [eks\_default\_worker\_group\_additional\_userdata](#input\_eks\_default\_worker\_group\_additional\_userdata) | Userdata to append to the default userdata of the default EKS worker group | `number` | `1` | no |
| <a name="input_eks_default_worker_group_asg_desired_capacity"></a> [eks\_default\_worker\_group\_asg\_desired\_capacity](#input\_eks\_default\_worker\_group\_asg\_desired\_capacity) | The Autoscaling Group size of the default EKS worker group | `number` | `4` | no |
| <a name="input_eks_default_worker_group_asg_max_capacity"></a> [eks\_default\_worker\_group\_asg\_max\_capacity](#input\_eks\_default\_worker\_group\_asg\_max\_capacity) | The Autoscaling Group size of the default EKS worker group | `number` | `10` | no |
| <a name="input_eks_default_worker_group_asg_min_capacity"></a> [eks\_default\_worker\_group\_asg\_min\_capacity](#input\_eks\_default\_worker\_group\_asg\_min\_capacity) | The Autoscaling Group size of the default EKS worker group | `number` | `1` | no |
| <a name="input_eks_default_worker_group_instance_type"></a> [eks\_default\_worker\_group\_instance\_type](#input\_eks\_default\_worker\_group\_instance\_type) | The instance type of the default EKS worker group | `string` | `"m5.large"` | no |
| <a name="input_eks_default_worker_group_name"></a> [eks\_default\_worker\_group\_name](#input\_eks\_default\_worker\_group\_name) | The name of the default EKS worker group | `string` | `"default-worker-group"` | no |
| <a name="input_eks_jobs_arm_worker_group_asg_desired_capacity"></a> [eks\_jobs\_arm\_worker\_group\_asg\_desired\_capacity](#input\_eks\_jobs\_arm\_worker\_group\_asg\_desired\_capacity) | The Autoscaling Group size of the ARM EKS worker group | `number` | `1` | no |
| <a name="input_eks_jobs_arm_worker_group_asg_max_capacity"></a> [eks\_jobs\_arm\_worker\_group\_asg\_max\_capacity](#input\_eks\_jobs\_arm\_worker\_group\_asg\_max\_capacity) | The Autoscaling Group size of the ARM EKS worker group | `number` | `3` | no |
| <a name="input_eks_jobs_arm_worker_group_asg_min_capacity"></a> [eks\_jobs\_arm\_worker\_group\_asg\_min\_capacity](#input\_eks\_jobs\_arm\_worker\_group\_asg\_min\_capacity) | The Autoscaling Group size of the ARM EKS worker group | `number` | `1` | no |
| <a name="input_eks_jobs_arm_worker_group_instance_type"></a> [eks\_jobs\_arm\_worker\_group\_instance\_type](#input\_eks\_jobs\_arm\_worker\_group\_instance\_type) | The instance type of the jobs ARM EKS worker group | `string` | `"m6g.large"` | no |
| <a name="input_eks_jobs_arm_worker_group_name"></a> [eks\_jobs\_arm\_worker\_group\_name](#input\_eks\_jobs\_arm\_worker\_group\_name) | The name of the jobs EKS worker group | `string` | `"jobs-arm-worker-group"` | no |
| <a name="input_eks_jobs_worker_group_additional_userdata"></a> [eks\_jobs\_worker\_group\_additional\_userdata](#input\_eks\_jobs\_worker\_group\_additional\_userdata) | Userdata to append to the default userdata of the jobs EKS worker group | `number` | `1` | no |
| <a name="input_eks_jobs_worker_group_asg_desired_capacity"></a> [eks\_jobs\_worker\_group\_asg\_desired\_capacity](#input\_eks\_jobs\_worker\_group\_asg\_desired\_capacity) | The Autoscaling Group size of the jobs EKS worker group | `number` | `4` | no |
| <a name="input_eks_jobs_worker_group_asg_max_capacity"></a> [eks\_jobs\_worker\_group\_asg\_max\_capacity](#input\_eks\_jobs\_worker\_group\_asg\_max\_capacity) | The Autoscaling Group size of the jobs EKS worker group | `number` | `10` | no |
| <a name="input_eks_jobs_worker_group_asg_min_capacity"></a> [eks\_jobs\_worker\_group\_asg\_min\_capacity](#input\_eks\_jobs\_worker\_group\_asg\_min\_capacity) | The Autoscaling Group size of the jobs EKS worker group | `number` | `1` | no |
| <a name="input_eks_jobs_worker_group_instance_type"></a> [eks\_jobs\_worker\_group\_instance\_type](#input\_eks\_jobs\_worker\_group\_instance\_type) | The instance type of the jobs EKS worker group | `string` | `"m5.large"` | no |
| <a name="input_eks_jobs_worker_group_name"></a> [eks\_jobs\_worker\_group\_name](#input\_eks\_jobs\_worker\_group\_name) | The name of the jobs EKS worker group | `string` | `"jobs-worker-group"` | no |
| <a name="input_eks_users"></a> [eks\_users](#input\_eks\_users) | Additional IAM users to add to the aws-auth configmap. | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/jonah.jones",<br>    "username": "jonah.jones"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/fontanalorenz@gmail.com",<br>    "username": "fontanalorenz@gmail.com"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/leodidonato@gmail.com",<br>    "username": "leodidonato@gmail.com"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/leonardo.grasso",<br>    "username": "leonardo.grasso"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/massimiliano.giovagnoli",<br>    "username": "massimiliano.giovagnoli"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/circleci",<br>    "username": "circleci"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/michele@zuccala.com",<br>    "username": "michele@zuccala.com"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/federico.dipierro",<br>    "username": "federico.dipierro"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/luca.guerra",<br>    "username": "luca.guerra"<br>  }<br>]</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"eu-west-1"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | The CIDR block of the main VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_enable_dns_hostnames"></a> [vpc\_enable\_dns\_hostnames](#input\_vpc\_enable\_dns\_hostnames) | A boolean flag to enable/disable DNS hostnames in the main VPC | `bool` | `true` | no |
| <a name="input_vpc_enable_nat_gateway"></a> [vpc\_enable\_nat\_gateway](#input\_vpc\_enable\_nat\_gateway) | A boolean flag to provision NAT Gateways for each of your private networks | `bool` | `true` | no |
| <a name="input_vpc_private_subnets_cidr_blocks"></a> [vpc\_private\_subnets\_cidr\_blocks](#input\_vpc\_private\_subnets\_cidr\_blocks) | The CIDR blocks of the main VPC's public subnets | `list` | `[]` | no |
| <a name="input_vpc_public_subnets_cidr_blocks"></a> [vpc\_public\_subnets\_cidr\_blocks](#input\_vpc\_public\_subnets\_cidr\_blocks) | The CIDR blocks of the main VPC's public subnets | `list` | `[]` | no |
| <a name="input_vpc_single_nat_gateway"></a> [vpc\_single\_nat\_gateway](#input\_vpc\_single\_nat\_gateway) | A boolean flag to provision a single shared NAT Gateway across all of your private networks | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deck_aws_acm_certificate_arn"></a> [deck\_aws\_acm\_certificate\_arn](#output\_deck\_aws\_acm\_certificate\_arn) | n/a |
| <a name="output_deck_aws_acm_certificate_validation_options"></a> [deck\_aws\_acm\_certificate\_validation\_options](#output\_deck\_aws\_acm\_certificate\_validation\_options) | n/a |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | Endpoint for EKS control plane. |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | Kubernetes Cluster Name |
| <a name="output_eks_cluster_security_group_id"></a> [eks\_cluster\_security\_group\_id](#output\_eks\_cluster\_security\_group\_id) | Security group ids attached to the cluster control plane. |
| <a name="output_region"></a> [region](#output\_region) | AWS region |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The VPC id where the cluster is provisioned to |
