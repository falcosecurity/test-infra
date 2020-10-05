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

Copy the environment var file from the sample `demo.tfvars.sample`:

```shell
cp demo.tfvars.sample demo.tfvars
```

## Create

Make sure `terraform_state_backend_force_destroy` is set to `false`. Compile the other variables as for your needings.

After you've done this,  and initalize your Terraform workspace, which will download the provider and initialize it with the values provided in the `<environment>.tfvars` file.

```shell
$ terraform init
Initializing modules...
Downloading terraform-aws-modules/eks/aws 9.0.0 for eks...

# Output truncated...

Terraform has been successfully initialized!
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

At this point, the Terraform state is still stored locally.
Module `terraform_state_backend` also creates a new `terraform_backend.tf` file that defines the S3 state backend.
Henceforth, Terraform will also read this newly-created backend definition file.
Now, move your local state to the Terraform remote state backend, by running:

```
terraform init -force-copy
```

Now the state is stored in the S3 bucket, and the DynamoDB table will be used to lock the state to prevent concurrent modification.

## Destroy

Now make sure `terraform_state_backend_force_destroy` is set to `true` and `terraform_state_backend_file_path` is set to "" (empty string).
Delete the `terraform_backend.tf` file and enabling deletion of the S3 state bucket, by running:

```
terraform apply -target module.terraform_state_backend
```

Move the Terraform remote state to local filesystem, by running:

```
terraform init -force-copy
```

Now the state is once again stored locally and the S3 state bucket can be safely deleted.
Delete the EKS cluster infrastructure:

```
terraform destroy
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
