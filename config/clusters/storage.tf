resource "aws_s3_bucket" "prow_storage" {
  bucket = "${local.cluster_name}-prow"
  acl    = "private"

  tags = module.label.tags

  lifecycle {
    prevent_destroy = true
  }
}
