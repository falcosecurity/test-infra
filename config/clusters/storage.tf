resource "aws_s3_bucket" "prow_storage" {
  bucket = "falco-prow-logs"

  acl = "private"

  lifecycle_rule {
    id      = "ten_day_retention_logs"
    prefix  = "logs/"
    enabled = true
    expiration {
      days = 10
    }
  }

  lifecycle_rule {
    id      = "ten_day_retention_pr_logs"
    prefix  = "pr-logs/"
    enabled = true
    expiration {
      days = 10
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.prow_storage.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = module.label.tags
}

resource "aws_kms_key" "prow_storage" {
  description             = "Prow storage master encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket_policy" "prow_storage" {
  bucket = aws_s3_bucket.prow_storage.id
  policy = data.aws_iam_policy_document.prow_storage.json
}

data "aws_iam_policy_document" "prow_storage" {
  statement {
    sid    = "AllowProwAllToS3Storage"
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.prow_storage.arn,
      "${aws_s3_bucket.prow_storage.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [module.iam_assumable_role_admin.this_iam_role_arn] # Prow IAM Role
    }
  }
}

