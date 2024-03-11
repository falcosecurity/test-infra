resource "aws_s3_bucket" "playground_bucket" {
  bucket = var.playground_bucket_name
  tags = {
    Name = var.playground_bucket_name
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
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

resource "aws_s3_bucket_public_access_block" "playground_bucket_public_access" {
  bucket = aws_s3_bucket.playground_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "playground_bucket_policy" {
  bucket = aws_s3_bucket.playground_bucket.id
  policy = data.aws_iam_policy_document.playground_bucket_policy_document.json
}

data "aws_iam_policy_document" "playground_bucket_policy_document" {
  statement {
    sid = "AllowPublicRead"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.playground_bucket.arn}/*",
    ]

  }

  statement {
    sid = "HTTPSOnly"
    effect = "Deny"
    
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.playground_bucket.arn}/*",
    ]

    condition {
      variable = "aws:SecureTransport"
      test = "Bool"
      values = ["false"]
    }
  }
}

resource "aws_acm_certificate" "playground_cert" {
  domain_name       = var.playground_name_alias
  validation_method = "DNS"
  provider          = aws.us

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "playground" {
  origin {
    domain_name = aws_s3_bucket.playground_bucket.bucket_regional_domain_name
    origin_id   = var.playground_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Falco playground"
  default_root_object = "index.html"

  aliases = [var.playground_name_alias]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.playground_origin_id

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
    acm_certificate_arn = aws_acm_certificate.playground_cert.arn
    ssl_support_method  = "sni-only"
  }

  lifecycle {
    prevent_destroy = true
  }
}
