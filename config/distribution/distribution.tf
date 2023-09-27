resource "aws_s3_bucket" "distribution_bucket" {
  bucket = var.bucket_name
  acl    = "public-read"
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
          "Sid": "HTTPSOnly",
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": "arn:aws:s3:::${var.bucket_name}/*",
          "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
        },
        {
            "Sid": "AllowPublicRead",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
    ]
}
EOF
  tags = {
    Name = var.bucket_name
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    # allowed_origins = ["https://${var.distribution_name_alias}"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  server_side_encryption_configuration {
    rule {
      bucket_key_enabled = false
      
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_object" "distribution_index" {
  bucket       = aws_s3_bucket.distribution_bucket.id
  key          = "index.html"
  acl          = "public-read"
  source       = "files/index.html"
  etag         = filemd5("files/index.html")
  content_type = "text/html; charset=utf-8"
}

# source: https://github.com/rufuspollock/s3-bucket-listing
resource "aws_s3_bucket_object" "distribution_list_js" {
  bucket       = aws_s3_bucket.distribution_bucket.id
  key          = "s3-list.js"
  acl          = "public-read"
  source       = "files/s3-list.js"
  etag         = filemd5("files/s3-list.js")
  content_type = "text/javascript; charset=utf-8"
}

resource "aws_s3_bucket" "logging_bucket" {
  bucket = var.logging_bucket_name
  #acl    = "private"

  grant {
    id = "6e179ab6a522e9123d39ace0dace05f83ca531f9e778367bb90199a80786c709"
    permissions = [
      "FULL_CONTROL",
    ]
    type = "CanonicalUser"
  }

  grant {
    id = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
    permissions = [
      "FULL_CONTROL",
    ]
    type = "CanonicalUser"
  }

  tags = {
    Name = var.logging_bucket_name
  }

  server_side_encryption_configuration {
    rule {
      bucket_key_enabled = false
      
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.distribution_name_alias
  validation_method = "DNS"
  provider          = aws.us

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.distribution_bucket.bucket_regional_domain_name
    origin_id   = var.distribution_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Falco distribution channel"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "${var.logging_bucket_name}.s3.amazonaws.com"
    prefix          = "falco-distribution"
  }

  aliases = [var.distribution_name_alias]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.distribution_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
  }

  lifecycle {
    prevent_destroy = true
  }
}
