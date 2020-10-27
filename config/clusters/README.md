# Falco Test Infra on AWS

This repo is a companion repo to the [Provision an EKS Cluster learn guide](https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster), containing
Terraform configuration files to provision an EKS cluster on AWS.

After installing the AWS CLI. Configure it to use your credentials.

```shell
$ aws configure
AWS Access Key ID [None]: <YOUR_AWS_ACCESS_KEY_ID>
AWS Secret Access Key [None]: <YOUR_AWS_SECRET_ACCESS_KEY>
Default region name [None]: <YOUR_AWS_REGION>
Default output format [None]: json
```

This enables Terraform access to the configuration file and performs operations on your behalf with these security credentials.

Copy the environment var file from the sample `prow.tfvars.sample`:

```shell
cp prow.tfvars.sample prow.tfvars
```

## Create

### The state backend infrastructure

First of all, the remote state backend is required in order to manage the state for this infrastructure (and different instances of this infrastructure through use of workspaces, and also the backend infrastructure itself, which should be managed with a dedicated workspace).
In this way, we can maintain a single remote state backend for this project.

```shell
terraform init ./state-backend
```

Manage the state for the backend infrastructure itself in a dedicated workspace, so:

```shell
terraform workspace new state-backend ./state-backend
```

And now create the remote state backend:

```shell
terraform apply -var-file=./state-backend/all.tfvars ./state-backend
```

Besides the remote infrastructure, also the local configuration files to use the backend are created (`./terraform_backend.tf` and `./state-backend/terraform_backend.tf` by default).
So now as the state is still stored locally, you have to move the state to the just created backend.

```
terraform init -force-copy ./state-backend
```

Now the state is stored in the S3 bucket, and the DynamoDB table will be used to lock the state to prevent concurrent modification.

### The cluster infrastructure

After you've done this,  and initalize your Terraform workspace, which will download the provider and initialize it with the values provided in the `<environment>.tfvars` file.

```shell
$ terraform init
Initializing modules...
Downloading terraform-aws-modules/eks/aws 9.0.0 for eks...

# Output truncated...

Terraform has been successfully initialized!
```

Create a dedicated workspace for this cluster environment:

```shell
terraform workspace new <environment>

```

Then, provision your EKS cluster and the Terraform state backend itself on S3 with state locking on DynamoDB, by running `terraform apply`. This will 
take approximately 10 minutes.

```shell
$ terraform apply -var-file <environment>.tfvars

# Confirm plan apply

# Output truncated...

Apply complete! Resources: 51 added, 0 changed, 0 destroyed.

Outputs:

# Output truncated...
```

## Destroy

### The cluster infrastructure

Make sure to select the correct environment workspace:

```shell
terraform workspace select <environment>
```

Destroy the cluster infrastructure:

```shell
terraform destroy
```

### The state backend infrastructure

Caution: do not do it unless you have a valid reason! 

#### You really want to destroy the state backend with all the states

Make sure to select the correct environment workspace:

```shell
terraform workspace select state-backend
```

By default if the s3 bucket backend contains states (thus objects) the destroy of that resource will be prevented.
In order to force the destroy, make sure `terraform_state_backend_force_destroy` is set to `true` and `terraform_state_backend_file_path` is set to "" (empty string).

Delete the `terraform_backend.tf` file and enabling deletion of the S3 state bucket, by running:

```shell
terraform apply -var-file=./state-backend/all.tfvars ./state-backend
```

Move the Terraform remote state to local filesystem, by running:

```shell
terraform init -force-copy ./state-backend
```

Now the state is once again stored locally and the S3 state bucket can be safely deleted.
Delete the state backend infrastructure:

```
terraform destroy -var-file=./state-backend/all.tfvars ./state-backend
```

Examine local state file `terraform.tfstate` to verify that it contains no resources.

## Configure kubectl

To configure kubetcl, you need both [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

The following command will get the access credentials for your cluster and automatically
configure `kubectl`.

```shell
$ aws eks --region <region> update-kubeconfig --name <cluster_name>
```

The
[Kubernetes cluster name](https://github.com/hashicorp/learn-terraform-eks/blob/master/outputs.tf#L26)
and [region](https://github.com/hashicorp/learn-terraform-eks/blob/master/outputs.tf#L21)
 correspond to the output variables showed after the successful Terraform run.

You can view these outputs again by running:

```shell
$ terraform output
```

---

# [Terraform specs](./TERRAFORM.md)


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
terraform init
terraform apply
```

## First initialization

**Warning**: only do this if this distribution infrastructure is not
yet on your cluster. If it is, you will damage the state.

Copy the environment var file from the sample `distribution.tfvars.sample`:

```console
$ cp distribution.tfvars.sample distribution.tfvars
```

Make sure that the terraform state on S3 configuration is hidden from terraform
since we didn't create the bucket and DynamoDB locking table yet.

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
