data "aws_canonical_user_id" "current_user" {}

data "aws_caller_identity" "current" {}

##### EBS CSI controller

module "ebs_csi_controller" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "4.1.0"
  create_role      = true
  role_name        = "${local.cluster_name}-ebs-csi-controller"
  provider_url     = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [aws_iam_policy.ebs_controller_policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:ebs-csi-controller-sa",
  ]
}

resource "aws_iam_policy" "ebs_controller_policy" {
  name_prefix = "${local.cluster_name}-ebs-csi-driver"
  policy      = data.aws_iam_policy_document.ebs_controller_policy_doc.json
}

data "aws_iam_policy_document" "ebs_controller_policy_doc" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]

    actions = ["ec2:CreateTags"]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]

    actions = ["ec2:DeleteTags"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateVolume"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateVolume"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/created-for/pvc/name"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteSnapshot"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteSnapshot"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}

##### Cluster-autoscaler

module "cluster_autoscaler" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "4.1.0"
  create_role      = true
  role_name        = "${local.cluster_name}-cluster-autoscaler"
  provider_url     = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns = [aws_iam_policy.cluster_autoscaler_policy.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:cluster-autoscaler",
  ]
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name_prefix = "${local.cluster_name}-cluster-autoscaler"
  policy      = data.aws_iam_policy_document.cluster_autoscaler_policy_doc.json
}

data "aws_iam_policy_document" "cluster_autoscaler_policy_doc" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]
  }
}

##### S3 for Prow uploads

module "iam_assumable_role_admin" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "4.1.0"
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
  version          = "4.1.0"
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

##### Permissions for GitHub Actions

# GHA OIDC Provider, required to integrate with any GHA workflow
module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "5.10.0"
}

# Rules repository

module "rules_s3_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.10.0"
  create  = true
  subjects = [
    "falcosecurity/rules:ref:refs/heads/main",
    "falcosecurity/rules:ref:refs/tags/*"
  ]
  policies = {
    rules_s3_access = "${aws_iam_policy.rules_s3_access.arn}"
  }
}

resource "aws_iam_policy" "rules_s3_access" {
  name_prefix = "github_actions-rules-s3"
  description = "GitHub actions S3 access policy for rules"
  policy      = data.aws_iam_policy_document.rules_s3_access.json
}

data "aws_iam_policy_document" "rules_s3_access" {
  statement {
    sid    = "UploadRulesS3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::falco-distribution/rules/*",
      "arn:aws:s3:::falco-distribution/rules",
    ]
  }
}

# Plugins repository

module "plugins_s3_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.10.0"
  name    = "github_actions-plugins-s3"
  create  = true
  subjects = [
    "falcosecurity/plugins:ref:refs/heads/main",
    "falcosecurity/plugins:ref:refs/tags/*"
  ]
  policies = {
    plugins_s3_access = "${aws_iam_policy.plugins_s3_access.arn}"
  }
}

resource "aws_iam_policy" "plugins_s3_access" {
  name_prefix = "github_actions-plugins-s3"
  description = "GitHub actions S3 access policy for plugins repo workflows"
  policy      = data.aws_iam_policy_document.plugins_s3_access.json
}

data "aws_iam_policy_document" "plugins_s3_access" {
  statement {
    sid    = "UploadPluginsS3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::falco-distribution/plugins/*",
      "arn:aws:s3:::falco-distribution/plugins/",
    ]
  }
}

# Test-infra repository

module "test-infra_cluster_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.10.0"
  name    = "github_actions-test-infra-cluster"
  create  = true
  subjects = [
    "falcosecurity/test-infra:ref:refs/heads/master"
  ]
  policies = {
    test-infra_cluster_access = "${aws_iam_policy.test-infra_cluster_access.arn}"
  }
}

resource "aws_iam_policy" "test-infra_cluster_access" {
  name_prefix = "github_actions-test-infra-cluster"
  description = "GitHub actions cluster access policy for test-infra master terraform/prow deploy"
  policy      = data.aws_iam_policy_document.test-infra_cluster_access.json
}

data "aws_iam_policy_document" "test-infra_cluster_access" {
  statement {
    sid    = "DeployTestInfraClusterAccess"
    effect = "Allow"
    actions = [
      "*"
    ]
    resources = [
      "*"
    ]
  }
}

module "test-infra_reader" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.10.0"
  name    = "github_actions-test-infra-reader"
  create  = true
  subjects = [
    "falcosecurity/test-infra:pull_request"
  ]
  policies = {
    test-infra_read_access = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    test-infra_state_lock  = "${aws_iam_policy.test-infra_state_lock.arn}"
  }
}

resource "aws_iam_policy" "test-infra_state_lock" {
  name_prefix = "github_actions-test-infra-cluster"
  description = "Access policy for test-infra Terraform remote state lock"
  policy      = data.aws_iam_policy_document.test-infra_state_lock.json
}

data "aws_iam_policy_document" "test-infra_state_lock" {
  statement {
    sid    = "DeployTestInfraClusterAccess"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:::table/${var.state_dynamodb_table_name}"
    ]
  }
}

module "test-infra_s3_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.10.0"
  name    = "github_actions-test-infra-s3"
  create  = true
  subjects = [
    "falcosecurity/test-infra:ref:refs/heads/master"
  ]
  policies = {
    test-infra_s3_access = "${aws_iam_policy.test-infra_s3_access.arn}"
  }
}

resource "aws_iam_policy" "test-infra_s3_access" {
  name_prefix = "github_actions-test-infra-s3"
  description = "GitHub actions S3 access policy for test-infra update-drivers-website workflow"
  policy      = data.aws_iam_policy_document.test-infra_s3_access.json
}

data "aws_iam_policy_document" "test-infra_s3_access" {
  statement {
    sid    = "UploadTestInfraS3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::falco-distribution/driver/site/*",
      "arn:aws:s3:::falco-distribution/driver/site",
    ]
  }
}

# Falco repository (dev packages)

module "falco_dev_s3_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.10.0"
  name    = "github_actions-falco-dev-s3"
  create  = true
  subjects = [
    "falcosecurity/falco:ref:refs/heads/master",
    "falcosecurity/falco:ref:refs/tags/*"
  ]
  policies = {
    falco_s3_access = "${aws_iam_policy.falco_dev_s3_access.arn}"
  }
}

resource "aws_iam_policy" "falco_dev_s3_access" {
  name_prefix = "github_actions-falco-dev-s3"
  description = "GitHub actions S3 access policy for falco repo dev workflows"
  policy      = data.aws_iam_policy_document.falco_dev_s3_access.json
}

data "aws_iam_policy_document" "falco_dev_s3_access" {
  statement {
    sid    = "UploadFalcoDevS3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::falco-distribution/packages/*-dev/*",
      "arn:aws:s3:::falco-distribution/packages/*-dev/",
    ]
  }
  statement {
    sid    = "BuildFalcoDevCloudFrontAccess"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      "arn:aws:cloudfront::292999226676:distribution/E1CQNPFWRXLGQD"
    ]
  }
}

# Falco repository (releases)

module "falco_s3_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.10.0"
  name    = "github_actions-falco-s3"
  create  = true
  subjects = [
    "falcosecurity/falco:ref:refs/tags/*"
  ]
  policies = {
    falco_s3_access = "${aws_iam_policy.falco_s3_access.arn}"
  }
}

resource "aws_iam_policy" "falco_s3_access" {
  name_prefix = "github_actions-falco-s3"
  description = "GitHub actions S3 access policy for falco repo workflows"
  policy      = data.aws_iam_policy_document.falco_s3_access.json
}

data "aws_iam_policy_document" "falco_s3_access" {
  statement {
    sid    = "UploadFalcoS3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::falco-distribution/packages/*",
      "arn:aws:s3:::falco-distribution/packages/",
    ]
  }
  statement {
    sid    = "BuildFalcoCloudFrontAccess"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      "arn:aws:cloudfront::292999226676:distribution/E1CQNPFWRXLGQD"
    ]
  }
}

# Falco repository (ECR)

module "falco_ecr_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  name    = "github_actions-falco-ecr"
  version = "5.10.0"
  create  = true
  subjects = [
    "falcosecurity/falco:ref:refs/heads/master",
    "falcosecurity/falco:ref:refs/tags/*"
  ]
  policies = {
    falco_ecr_access = "${aws_iam_policy.falco_ecr_access.arn}"
  }
}

resource "aws_iam_policy" "falco_ecr_access" {
  name_prefix = "github_actions-falco-ecr"
  description = "GitHub actions ECR access policy for falco"
  policy      = data.aws_iam_policy_document.falco_ecr_access.json
}

data "aws_iam_policy_document" "falco_ecr_access" {
  statement {
    sid    = "BuildFalcoECRAccess"
    effect = "Allow"
    actions = [
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:GetRepositoryPolicy",
      "ecr-public:DescribeRepositories",
      "ecr-public:DescribeImages",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:UploadLayerPart",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:PutImage"
    ]
    resources = [
      "arn:aws:ecr-public::292999226676:repository/falco",
      "arn:aws:ecr-public::292999226676:repository/falco-driver-loader",
      "arn:aws:ecr-public::292999226676:repository/falco-no-driver",
      "arn:aws:ecr-public::292999226676:repository/falco-driver-loader-legacy",
      "arn:aws:ecr-public::292999226676:repository/falco-distroless"
    ]
  }
  statement {
    sid    = "BuildFalcoECRTokenAccess"
    effect = "Allow"
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }
}

# Falcosidekick repository

module "falcosidekick_ecr_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  name    = "github_actions-falcosidekick-ecr"
  version = "5.10.0"
  create  = true
  subjects = [
    "falcosecurity/falcosidekick:ref:refs/heads/master",
    "falcosecurity/falcosidekick:ref:refs/tags/*"
  ]
  policies = {
    falcosidekick_ecr_access = "${aws_iam_policy.falcosidekick_ecr_access.arn}"
  }
}

resource "aws_iam_policy" "falcosidekick_ecr_access" {
  name_prefix = "github_actions-falcosidekick-ecr"
  description = "GitHub actions ECR access policy for falcosidekick"
  policy      = data.aws_iam_policy_document.falcosidekick_ecr_access.json
}

data "aws_iam_policy_document" "falcosidekick_ecr_access" {
  statement {
    sid    = "BuildFalcosidekickECRAccess"
    effect = "Allow"
    actions = [
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:GetRepositoryPolicy",
      "ecr-public:DescribeRepositories",
      "ecr-public:DescribeImages",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:UploadLayerPart",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:PutImage"
    ]
    resources = [
      "arn:aws:ecr-public::292999226676:repository/falcosidekick"
    ]
  }
  statement {
    sid    = "BuildFalcosidekickECRTokenAccess"
    effect = "Allow"
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }
}

# Falcosidekick-UI repository

module "falcosidekick_ui_ecr_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  name    = "github_actions-falcosidekick-ui-ecr"
  version = "5.10.0"
  create  = true
  subjects = [
    "falcosecurity/falcosidekick-ui:ref:refs/heads/master",
    "falcosecurity/falcosidekick-ui:ref:refs/tags/*"
  ]
  policies = {
    falcosidekick_ui_ecr_access = "${aws_iam_policy.falcosidekick_ui_ecr_access.arn}"
  }
}

resource "aws_iam_policy" "falcosidekick_ui_ecr_access" {
  name_prefix = "github_actions-falcosidekick-ui-ecr"
  description = "GitHub actions ECR access policy for falcosidekick-ui"
  policy      = data.aws_iam_policy_document.falcosidekick_ui_ecr_access.json
}

data "aws_iam_policy_document" "falcosidekick_ui_ecr_access" {
  statement {
    sid    = "BuildFalcosidekickUIECRAccess"
    effect = "Allow"
    actions = [
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:GetRepositoryPolicy",
      "ecr-public:DescribeRepositories",
      "ecr-public:DescribeImages",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:UploadLayerPart",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:PutImage"
    ]
    resources = [
      "arn:aws:ecr-public::292999226676:repository/falcosidekick-ui"
    ]
  }
  statement {
    sid    = "BuildFalcosidekickUIECRTokenAccess"
    effect = "Allow"
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }
}

# Falcoctl repository

module "falcoctl_ecr_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  name    = "github_actions-falcoctl-ecr"
  version = "5.10.0"
  create  = true
  subjects = [
    "falcosecurity/falcoctl:ref:refs/heads/main",
    "falcosecurity/falcoctl:ref:refs/tags/*"
  ]
  policies = {
    falcoctl_ecr_access = "${aws_iam_policy.falcoctl_ecr_access.arn}"
  }
}

resource "aws_iam_policy" "falcoctl_ecr_access" {
  name_prefix = "github_actions-falcoctl-ecr"
  description = "GitHub actions ECR access policy for falcoctl"
  policy      = data.aws_iam_policy_document.falcoctl_ecr_access.json
}

data "aws_iam_policy_document" "falcoctl_ecr_access" {
  statement {
    sid    = "BuildFalcoctlECRAccess"
    effect = "Allow"
    actions = [
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:GetRepositoryPolicy",
      "ecr-public:DescribeRepositories",
      "ecr-public:DescribeImages",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:UploadLayerPart",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:PutImage"
    ]
    resources = [
      "arn:aws:ecr-public::292999226676:repository/falcoctl"
    ]
  }
  statement {
    sid    = "BuildFalcoctlECRTokenAccess"
    effect = "Allow"
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }
}

# falco-playground repository

module "falco_playground_s3_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.10.0"
  name    = "github_actions-falco-playground-s3"
  create  = true
  subjects = [
    "falcosecurity/falco-playground:ref:refs/tags/*"
  ]
  policies = {
    falco_playground_s3_access = "${aws_iam_policy.falco_playground_s3_access.arn}"
  }
}

resource "aws_iam_policy" "falco_playground_s3_access" {
  name_prefix = "github_actions-falco-playground-s3"
  description = "GitHub actions S3 access policy for falco-playground repo workflows"
  policy      = data.aws_iam_policy_document.falco_playground_s3_access.json
}

data "aws_iam_policy_document" "falco_playground_s3_access" {
  statement {
    sid    = "UploadFalcoPlaygroundS3ContentAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::falco-playground/*",
      "arn:aws:s3:::falco-playground/",
    ]
  }
  statement {
    sid    = "UploadFalcoPlaygroundS3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::falco-playground",
    ]
  }
  statement {
    sid    = "BuildFalcoPlaygroundCloudFrontAccess"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      "arn:aws:cloudfront::292999226676:distribution/E3CTNHYRFR6C3"
    ]
  }
}

##### AWS LoadBalancer Controller

module "load_balancer_controller" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version          = "4.1.0"
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
    effect    = "Allow"
    resources = ["*"]
    actions   = ["iam:CreateServiceLinkedRole"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
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
      "elasticloadbalancing:DescribeTrustStores",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
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
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateSecurityGroup"]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    actions   = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateSecurityGroup"]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:security-group/*"]

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["true"]
    }

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*",
    ]

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
    ]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*",
    ]

    actions = ["elasticloadbalancing:AddTags"]

    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"

      values = [
        "CreateTargetGroup",
        "CreateLoadBalancer",
      ]
    }

    condition {
      test     = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values   = ["false"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"]

    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule",
    ]
  }
}
