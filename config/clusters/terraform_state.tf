resource "aws_s3_bucket" "falco-test-infra-state" {
  bucket = "falco-test-infra-state"
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = false
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
