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
  repository = aws_ecr_repository.update_jobs.name
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "golang" {
  repository = aws_ecr_repository.golang.name
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "build_drivers" {
  repository = aws_ecr_repository.build_drivers.name
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "docker_dind" {
  repository = aws_ecr_repository.docker_dind.name
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "build_plugins" {
  repository = aws_ecr_repository.build_plugins.name
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "update_deployment_files" {
  repository = aws_ecr_repository.update_deployment_files.name
  policy     = data.aws_iam_policy_document.ecr_standard.json
}

resource "aws_ecr_repository_policy" "update_dbg" {
  repository = aws_ecr_repository.update_dbg.name
  policy     = data.aws_iam_policy_document.ecr_standard.json
}
