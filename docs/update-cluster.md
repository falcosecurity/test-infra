# Cluster upgrade history


| Name | Updated |
| ------------- | ------------- |
| EKS Cluster Version  | 6/2021 |
| CoreDNS  | 6/2021  |
| Kube-proxy  | 6/2021  |
| VPC-CNI  | 6/2021  |
| EBS-CSI | 6/2021  |
| Cluster-Autoscaler  | 6/2021  |
| Alb-Controller  | 6/2021  |
| PushGateway  | 6/2021  |
| Metrics-Server  | 6/2021  |
| Check-config  | 6/2021  |
| Prowjob CRD  | 6/2021  |

# Updating cluster instructions


## EKS Master version

- update the version in Terraform eks [File](../config/clusters/eks.tf)

## EKS AMI are automatically updated my managed node group

## CoreDNS

- https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html

## Kube-proxy

- https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html

## VPC CNI

- https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html

## EBS CSI Driver

- Find the latest version https://github.com/kubernetes-sigs/aws-ebs-csi-driver
- Update the install version in the [script](../tools/deploy_prow.sh)

## Cluster Autoscaler

- Find the latest version https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html
- Update the install yaml in the [file](../config/prow/cluster-autoscaler.yaml)

## ALB Controller

- Find the latest version https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
- Update the yaml with the updated RBAC/image settings in this [file](../config/prow/alb_controller.yaml)


## Pushgateway

- Copy the settings from K8s [prow](https://github.com/kubernetes/test-infra/blob/master/config/prow/cluster/pushgateway_deployment.yaml), and apply those

## Metrics Server

- Find the latest version https://github.com/kubernetes-sigs/metrics-server
- Update the local file with the new version [file](../tools/deploy_prow.sh)


## Prow resources

- Some resources get updated by the weekly job https://prow.falco.org/job-history/s3/falco-prow-logs/logs/ci-test-infra-autobump-prow
- One's that are not udated and must be done manually
- - [Check config](../config/prow/check-config.yaml)
- - [Prowjob CRD](../config/prow/prowjob_custromresourcedefinition.yaml)