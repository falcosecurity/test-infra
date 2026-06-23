resource "aws_s3_bucket" "prow_storage" {
  bucket = "falco-prow-logs"

  policy = null

  tags = module.label.tags
}

resource "aws_s3_bucket_versioning" "prow_storage_versioning" {
  bucket = aws_s3_bucket.prow_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "prow_storage_lifecycle_configuration" {
  bucket = aws_s3_bucket.prow_storage.id

  rule {
    id      = "ten_day_retention_logs"
    filter {
      prefix  = "logs/"
    }

    expiration {
      days = 10
    }

    status = "Enabled"
  }

  rule {
    id      = "ten_day_retention_pr_logs"

    filter {
      prefix  = "logs/"
    }

    expiration {
      days = 10
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prow_storage_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.prow_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.prow_storage.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "prow_storage_acl" {
  bucket = aws_s3_bucket.prow_storage.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "prow_storage" {
  bucket = aws_s3_bucket.prow_storage.id
  policy = data.aws_iam_policy_document.prow_storage.json
}

resource "aws_kms_key" "prow_storage" {
  description             = "Prow storage master encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
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
      identifiers = [module.iam_assumable_role_admin.iam_role_arn] # Prow IAM Role
    }
  }
}

