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

After you've done this, initalize your Terraform workspace, which will download 
the provider and initialize it with the values provided in the `terraform.tfvars` file.

```shell
$ terraform init
Initializing modules...
Downloading terraform-aws-modules/eks/aws 9.0.0 for eks...
- eks in .terraform/modules/eks/terraform-aws-modules-terraform-aws-eks-908c656
- eks.node_groups in .terraform/modules/eks/terraform-aws-modules-terraform-aws-eks-908c656/modules/node_groups
Downloading terraform-aws-modules/vpc/aws 2.6.0 for vpc...
- vpc in .terraform/modules/vpc/terraform-aws-modules-terraform-aws-vpc-4b28d3d

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "template" (hashicorp/template) 2.1.2...
- Downloading plugin for provider "kubernetes" (hashicorp/kubernetes) 1.10.0...
- Downloading plugin for provider "aws" (hashicorp/aws) 2.52.0...
- Downloading plugin for provider "random" (hashicorp/random) 2.2.1...
- Downloading plugin for provider "local" (hashicorp/local) 1.4.0...
- Downloading plugin for provider "null" (hashicorp/null) 2.1.2...

Terraform has been successfully initialized!
```

Copy the environment var file from the sample `demo.tfvars.sample`:

```shell
cp demo.tfvars.demo demo.tfvars
```

and compile it as for your needings.

Then, provision your EKS cluster by running `terraform apply`. This will 
take approximately 10 minutes.

```shell
$ terraform apply -var-file demo.tfvars

# Output truncated...

Plan: 51 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

# Output truncated...

Apply complete! Resources: 51 added, 0 changed, 0 destroyed.

Outputs:

cluster_endpoint = https://A1ADBDD0AE833267869C6ED0476D6B41.gr7.us-east-2.eks.amazonaws.com
cluster_security_group_id = sg-084ecbab456328732
kubectl_config = apiVersion: v1
preferences: {}
kind: Config

clusters:
- cluster:
    server: https://A1ADBDD0AE833267869C6ED0476D6B41.gr7.us-east-2.eks.amazonaws.com
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJd01ETXdPVEU0TXpVeU1sb1hEVE13TURNd056RTRNelV5TWxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTThkClZaN1lmbjZmWm41MEgwL0d1Qi9lRmVud2dydXQxQlJWd29nL1JXdFpNdkZaeStES0FlaG5lYnR5eHJ2VVZWMXkKTXVxelBiMzgwR3Vla3BTVnNTcDJVR0ptZ2N5UVBWVi9VYVZDQUpDaDZNYmIvL3U1bWFMUmVOZTBnb3VuMWlLbgpoalJBYlBJM2JvLzFPaGFuSXV1ejF4bmpDYVBvWlE1U2N5MklwNnlGZTlNbHZYQmJ6VGpESzdtK2VST2VpZUJWCjJQMGd0QXJ3alV1N2MrSmp6OVdvcGxCcTlHZ1RuNkRqT1laRHVHSHFRNEpDUnRsRjZBQXpTUVZ0cy9aRXBnMncKb2NHakd5ZE9pSmpMb1NsYU9weDIrMTNMbHcxMDAvNmY4Q0F2ajRIbFZUZDBQOW5rN1UyK04xNSt5VjRpNjFoQgp3bHl4SXFUWEhDR0JvYmRNNE5VQ0F3RUFBYU1qTUNFd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFIbEI3bGVMTnJYRXZnNksvNUdtR2s5Tlh4SUkKRDd0Y1dkTklBdnFka1hWK3ltVkxpTXV2ZGpQVjVKV3pBbEozTWJqYjhjcmlQWWxnVk1JNFJwc0N0aGJnajMzMwpVWTNESnNxSmZPUUZkUnkvUTlBbHRTQlBqQldwbEtaZGc2dklxS0R0eHB5bHovOE1BZ1RldjJ6Zm9SdzE4ZnhCCkI2QnNUSktxVGZCNCtyZytVcS9ULzBVS1VXS0R5K2gyUFVPTEY2dFVZSXhXM2RncWh0YWV3MGJnQmZyV3ZvSW8KYitSOVFDTk42UHRQNEFFQSsyQnJYYzhFTmd1M2EvNG9rN3lPMjZhTGJLdC9sbUNoNWVBOEdBRGJycHlWb3ZjVgpuTGdyb0FvRnVRMCtzYjNCTThUcEtxK0YwZ2dwSFptL3ZFNjh5NUk1VFlmUUdHeEZ6VEVyOHR5NHk1az0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  name: eks_training-eks-TNajBRIF

contexts:
- context:
    cluster: eks_training-eks-TNajBRIF
    user: eks_training-eks-TNajBRIF
  name: eks_training-eks-TNajBRIF

current-context: eks_training-eks-TNajBRIF

users:
- name: eks_training-eks-TNajBRIF
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "training-eks-TNajBRIF"



region = us-east-2
```

## Configure kubectl

To configure kubetcl, you need both [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [AWS IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

The following command will get the access credentials for your cluster and automatically
configure `kubectl`.

```shell
$ aws eks --region us-east-2 update-kubeconfig --name training-eks-sR8eLIil
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
