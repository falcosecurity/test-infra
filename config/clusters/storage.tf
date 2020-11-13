resource "aws_s3_bucket" "prow_storage" {
  bucket = "falco-prow-logs"
  acl    = "private"

  tags = module.label.tags

  lifecycle {
    prevent_destroy = false
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
}

resource "aws_kms_key" "prow_storage" {
  description             = "Prow storage master encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}
