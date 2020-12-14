data "aws_canonical_user_id" "current_user" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ebs_controller_policy_doc" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeVolumesModifications"
    ]
  }
}

resource "aws_iam_policy" "ebs_controller_policy" {
  name_prefix = "${local.cluster_name}-ebs-csi-driver"
  policy      = data.aws_iam_policy_document.ebs_controller_policy_doc.json
}

data "aws_iam_policy_document" "cluster_autoscaler_policy_doc" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]
  }
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name_prefix = "${local.cluster_name}-cluster-autoscaler"
  policy      = data.aws_iam_policy_document.cluster_autoscaler_policy_doc.json
}

##### S3 for Prow uploads

module "iam_assumable_role_admin" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "2.14.0"
  create_role      = true
  role_name        = "${local.cluster_name}-prow_s3_access"
  provider_url     = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [aws_iam_policy.s3_access.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.k8s_service_account_namespace}:tide",
    "system:serviceaccount:${local.k8s_service_account_namespace}:deck",
    "system:serviceaccount:${local.k8s_service_account_namespace}:crier",
    "system:serviceaccount:${local.k8s_service_account_namespace}:statusreconciler",
    "system:serviceaccount:${local.k8s_service_account_namespace}:prow-controller-manager"
  ]
}

resource "aws_iam_policy" "s3_access" {
  name_prefix = "${local.cluster_name}-prow-s3"
  description = "EKS s3 access policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.s3_access.json
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid    = "prows3access"
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.prow_storage.arn,
      "arn:aws:s3:::*/*",
    ]
  }

  statement {
    sid = "AllowToEncryptDecryptS3Bucket"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      aws_kms_key.prow_storage.arn,
    ]
  }
}

##### S3 for Prow uploads

module "driver_kit_s3_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "2.14.0"
  create_role      = true
  role_name        = "${local.cluster_name}-drivers_s3_access"
  provider_url     = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [aws_iam_policy.driverkit_s3_access.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.k8s_test_service_account_namespace}:driver-kit",
  ]
}

resource "aws_iam_policy" "driverkit_s3_access" {
  name_prefix = "${local.cluster_name}-driverkit-s3"
  description = "EKS s3 access policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.driverkit_s3_access.json
}

data "aws_iam_policy_document" "driverkit_s3_access" {
  statement {
    sid    = "driverkits3access"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::falco-distribution/driver/*",
      "arn:aws:s3:::falco-distribution/driver",
    ]
  }
}

##### AWS LoadBalancer Controller

module "load_balancer_controller" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "2.14.0"
  create_role      = true
  role_name        = "${local.cluster_name}-loadbalancer-controller"
  provider_url     = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [aws_iam_policy.loadbalancer_controller.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:aws-load-balancer-controller",
  ]
}

resource "aws_iam_policy" "loadbalancer_controller" {
  name_prefix = "${local.cluster_name}-lb-controller"
  description = "EKS loadbalancer controller policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.loadbalancer_controller.json
}

data "aws_iam_policy_document" "loadbalancer_controller" {
  statement {
    sid    = "loadbalancercontroller"
    effect = "Allow"

    actions = [
      "iam:CreateServiceLinkedRole",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = [
      "*"
    ]
  }
}
