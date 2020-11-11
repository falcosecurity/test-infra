resource "aws_acm_certificate" "deck" {
  domain_name       = "prow.falco.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}