resource "aws_dynamodb_table" "falco-test-infra-state-lock" {
  name           = "falco-test-infra-state-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
