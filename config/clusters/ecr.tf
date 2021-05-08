resource "aws_ecr_repository" "update_jobs" {
  name = "test-infra/update-jobs"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "golang" {
  name = "test-infra/golang"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "build_drivers" {
  name = "test-infra/build-drivers"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "docker_dind" {
  name = "test-infra/docker-dind"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "autobump" {
  name = "test-infra/autobump"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "arm_build" {
  name = "test-infra/arm-build"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "build_libs" {
  name = "test-infra/build-libs"
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_repository" "update_deployment_files" {
  name = "test-infra/update-falco-k8s-manifests"
  encryption_configuration {
    encryption_type = "KMS"
  }
}
# --- ECR Policies ---
resource "aws_ecr_repository_policy" "update_jobs" {
  repository = "test-infra/update-jobs"
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*/*"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:SetRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "golang" {
  repository = "test-infra/golang"
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*/*"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:SetRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "build_drivers" {
  repository = "test-infra/build-drivers"
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*/*"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:SetRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "docker_dind" {
  repository = "test-infra/docker-dind"
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*/*"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:SetRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "autobump" {
  repository = "test-infra/autobump"
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*/*"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:SetRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "arm_build" {
  repository = "test-infra/arm-build"
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*/*"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:SetRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "build_libs" {
  repository = "test-infra/build-libs"
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*/*"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:SetRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "update_deployment_files" {
  repository = "test-infra/update-falco-k8s-manifests"
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*/*"
            },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:SetRepositoryPolicy"
            ]
        }
    ]
}
EOF
}
