## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.2 |
| terraform | >= 0.12 |
| aws | >= 2.28.1 |

## Providers

| Name | Version |
|------|---------|
| local | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app\_name | n/a | `any` | n/a | yes |
| app\_namespace | n/a | `any` | n/a | yes |
| app\_stage | n/a | `any` | n/a | yes |
| region | AWS region | `string` | `"eu-west-1"` | no |
| terraform\_state\_backend\_config\_file\_name | The file name for the terraform backend config file. | `string` | `"terraform_backend.tf"` | no |
| terraform\_state\_backend\_force\_destroy | Whether to allow the S3 remote state backend to be deleted. Useful when migrating the state and/or destroying all the resources. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| region | AWS region |

