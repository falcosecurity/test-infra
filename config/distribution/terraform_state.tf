resource "aws_s3_bucket" "falco-distribution-state-bucket" {
  bucket = "falco-distribution-state-bucket"
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "falco-distribution-state-bucket-lock" {
  name           = "falco-distribution-state-bucket-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
