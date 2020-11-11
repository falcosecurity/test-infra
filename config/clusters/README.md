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

## Create

### The state backend infrastructure

First of all, the remote state backend is required in order to manage the state for this infrastructure (and different instances of this infrastructure through use of workspaces, and also the backend infrastructure itself, which should be managed with a dedicated workspace).
In this way, we can maintain a single remote state backend for this project.

The state is stored in an already created S3 bucket called

`falco-test-infra-state`

We define this as the backend for the state, and create a dynamoDB table for locking.

```shell
terraform init config/clusters

```

Then run apply to create the required infrastructure including the DynamoDB table lock. 

```
terraform apply -var-file config/clusters/prow.tfvars -auto-approve config/clusters
```

Now the state is stored in the S3 bucket, and the DynamoDB table will be used to lock the state to prevent concurrent modification.

# Output truncated...

Apply complete! Resources: 51 added, 0 changed, 0 destroyed.

Additional Outputs:

- EKS Kubeconfig copied locally


# Output truncated...
```
### Destroy the cluster infrastructure:

terraform destroy -var-file config/clusters/prow.tfvars -auto-approve config/clusters
```

### The state backend infrastructure

Caution: do not do it unless you have a valid reason! 

#### You really want to destroy the state backend with all the states

By default if the s3 bucket backend contains states (thus objects) the destroy of that resource will be prevented.
In order to force the destroy, make sure `terraform_state_backend_force_destroy` is set to `true` and `terraform_state_backend_file_path` is set to "" (empty string).

Delete the `terraform_backend.tf` file in the s3 bucket and enabling deletion of the S3 state bucket, by running:
s
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