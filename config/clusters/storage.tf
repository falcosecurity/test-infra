resource "aws_s3_bucket" "prow_storage" {
  bucket = "${module.label.id}-prow-storage"
  acl    = "private"

  tags = module.label.tags
}
