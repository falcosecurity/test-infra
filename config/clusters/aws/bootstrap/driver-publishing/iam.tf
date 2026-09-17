locals {
  issuer_hostpath = trimprefix(var.oke_oidc_issuer_url, "https://")
  driver_objects  = "arn:aws:s3:::${var.bucket_name}/driver/*"
}

resource "aws_iam_openid_connect_provider" "oke" {
  url            = var.oke_oidc_issuer_url
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "driver_publisher" {
  name                 = var.role_name
  description          = "Publish Falco drivers from the OKE driver-kit service account."
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oke.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.issuer_hostpath}:aud" = "sts.amazonaws.com"
          "${local.issuer_hostpath}:sub" = "system:serviceaccount:test-pods:driver-kit"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "driver_objects" {
  name = "driver-objects"
  role = aws_iam_role.driver_publisher.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadExistingDrivers"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = local.driver_objects
      },
      {
        Sid      = "PublishDrivers"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = local.driver_objects
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"                    = "public-read"
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid      = "PublishDriverAcl"
        Effect   = "Allow"
        Action   = ["s3:PutObjectAcl"]
        Resource = local.driver_objects
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "public-read"
          }
        }
      }
    ]
  })
}
