resource "aws_s3_bucket" "falco-test-infra-state" {
  bucket = "falco-test-infra-state"

  acl = "private"

  lifecycle {
    prevent_destroy = false
  }

  logging {
    target_bucket = aws_s3_bucket.falco-test-infra-state-logs.id
    target_prefix = "log/"
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

resource "aws_s3_bucket" "falco-test-infra-state-logs" {
  bucket = "falco-test-infra-state-logs"

  acl = "log-delivery-write"

  versioning {
    enabled = true
  }
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

