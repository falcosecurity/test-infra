resource "aws_s3_bucket" "falco-test-infra-state" {
  bucket = "falco-test-infra-state"

  acl = "private"

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.falco-test-infra-state.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = module.label.tags
}

resource "aws_kms_key" "falco-test-infra-state" {
  description             = "Falco Test Infra state master encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_dynamodb_table" "falco-test-infra-state-lock" {
  name           = "falco-test-infra-state-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}


resource "aws_s3_bucket_policy" "falco-test-infra-state" {
  bucket = aws_s3_bucket.falco-test-infra-state.id
  policy = data.aws_iam_policy_document.falco-test-infra-state.json
}

data "aws_iam_policy_document" "falco-test-infra-state" {
  statement {
    sid    = "AllowAllTestInfraUsersAccessToTestInfraState"
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.falco-test-infra-state.arn,
      "${aws_s3_bucket.falco-test-infra-state.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

