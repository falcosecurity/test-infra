data "aws_iam_policy_document" "ecr_standard" {
  statement {
    sid = "allowRWAccountOnly"
    actions = [
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
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
resource "aws_ecr_repository_policy" "update_jobs" {
  repository = "test-infra/update-jobs"
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "golang" {
  repository = "test-infra/golang"
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "build_drivers" {
  repository = "test-infra/build-drivers"
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "docker_dind" {
  repository = "test-infra/docker-dind"
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "autobump" {
  repository = "test-infra/autobump"
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "arm_build" {
  repository = "test-infra/arm-build"
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "build_libs" {
  repository = "test-infra/build-libs"
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "update_deployment_files" {
  repository = "test-infra/update-falco-k8s-manifests"
  policy     = data.aws_iam_policy_document.ecr_standard.json
}
