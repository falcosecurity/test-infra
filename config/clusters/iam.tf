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
}
