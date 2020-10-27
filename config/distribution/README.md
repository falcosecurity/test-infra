# Falco artifacts on S3

This repo contains an infrastructure implementation to host Falco distribution artifacts
on Amazon S3.

Proposal related to this document [here](https://github.com/falcosecurity/falco/blob/master/proposals/20201025-drivers-storage-s3.md).

After installing the AWS CLI. Configure it to use your credentials.

```console
$ aws configure
AWS Access Key ID [None]: <YOUR_AWS_ACCESS_KEY_ID>
AWS Secret Access Key [None]: <YOUR_AWS_SECRET_ACCESS_KEY>
Default region name [None]: <YOUR_AWS_REGION>
Default output format [None]: json
```

This enables Terraform access to the configuration file and performs operations on your behalf with these security credentials.

## Normal operations

If you are making changes to the terraform configuration here, your AWS account
will need to be able to read the `falco-distribution-state-bucket` S3 and read the
`falco-distribution-state-bucket-lock` DynamoDB table.

If you have that, you can just init and apply after you make changes.

```
terrafrom init
terraform apply
```

## First initialization

**Warning**: only do this if this distribution infrastructure is not
yet on your cluster. If it is, you will damage the state.

Copy the environment var file from the sample `distribution.tfvars.sample`:

```console
$ cp distribution.tfvars.sample distribution.tfvars
```

Make sure that the terraform state on s3 configuration is hidden from terraform
since we didn't create the bucket and dynamodb locking table yet.

```console
mv terraform_backend.tf terraform_backend.hold
```

Now, you can create everything, the state will still be located locally.

```console
terraform init
terraform apply
```

Now, let terraform know about the state configuration for s3.

```console
mv terraform_backend.hold terraform_backend.tf
```

Init and apply again to copy the configuration on s3.

```console
terraform init
terraform apply
```

From now on you can manage the distribution infra using the "Normal operations" section.


