## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.2 |
| terraform | >= 0.12 |
| aws | >= 2.28.1 |
| local | ~> 1.2 |
| null | ~> 2.1 |
| random | ~> 2.1 |
| template | ~> 2.1 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.28.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_name | n/a | `any` | n/a | yes |
| app\_namespace | n/a | `any` | n/a | yes |
| app\_stage | n/a | `any` | n/a | yes |
| eks\_default\_worker\_group\_additional\_userdata | Uerdata to append to the default userdata of the default EKS worker group | `number` | `1` | no |
| eks\_default\_worker\_group\_asg\_desired\_capacity | The Autoscaling Group size of the default EKS worker group | `number` | `1` | no |
| eks\_default\_worker\_group\_asg\_max\_capacity | The Autoscaling Group size of the default EKS worker group | `number` | `3` | no |
| eks\_default\_worker\_group\_asg\_min\_capacity | The Autoscaling Group size of the default EKS worker group | `number` | `1` | no |
| eks\_default\_worker\_group\_instance\_type | The instance type of the default EKS worker group | `string` | `"m5.large"` | no |
| eks\_default\_worker\_group\_name | The name of the default EKS worker group | `string` | `"default-worker-group"` | no |
| eks\_users | Additional IAM users to add to the aws-auth configmap. | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/jonah.jones",<br>    "username": "jonah.jones"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/fontanalorenz@gmail.com",<br>    "username": "fontanalorenz@gmail.com"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/leodidonato@gmail.com",<br>    "username": "leodidonato@gmail.com"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/leonardo.grasso",<br>    "username": "leonardo.grasso"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/massimiliano.giovagnoli",<br>    "username": "massimiliano.giovagnoli"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/spencer.krum",<br>    "username": "spencer.krum"<br>  },<br>  {<br>    "groups": [<br>      "system:masters"<br>    ],<br>    "userarn": "arn:aws:iam::292999226676:user/circleci",<br>    "username": "circleci"<br>  }<br>]</pre> | no |
| region | AWS region | `string` | `"eu-west-1"` | no |
| vpc\_cidr\_block | The CIDR block of the main VPC | `string` | `"10.0.0.0/16"` | no |
| vpc\_enable\_dns\_hostnames | A boolean flag to enable/disable DNS hostnames in the main VPC | `bool` | `true` | no |
| vpc\_enable\_nat\_gateway | A boolean flag to provision NAT Gateways for each of your private networks | `bool` | `true` | no |
| vpc\_private\_subnets\_cidr\_blocks | The CIDR blocks of the main VPC's public subnets | `list` | `[]` | no |
| vpc\_public\_subnets\_cidr\_blocks | The CIDR blocks of the main VPC's public subnets | `list` | `[]` | no |
| vpc\_single\_nat\_gateway | A boolean flag to provision a single shared NAT Gateway across all of your private networks | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| deck\_aws\_acm\_certificate\_arn | n/a |
| deck\_aws\_acm\_certificate\_validation\_options | n/a |
| eks\_cluster\_endpoint | Endpoint for EKS control plane. |
| eks\_cluster\_name | Kubernetes Cluster Name |
| eks\_cluster\_security\_group\_id | Security group ids attached to the cluster control plane. |
| region | AWS region |
| vpc\_id | The VPC id where the cluster is provisioned to |
