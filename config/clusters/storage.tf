resource "aws_s3_bucket" "prow_storage" {
  bucket = "falco-prow-logs"
  acl    = "private"

  tags = module.label.tags

  lifecycle {
    prevent_destroy = true
  }
}
