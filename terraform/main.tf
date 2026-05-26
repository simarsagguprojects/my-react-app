locals {
  account_id = "956651462310"
  smart_simar_arn = "arn:aws:iam::${local.account_id}:user/SmartSimar"
  github_actions_role_arn = "arn:aws:iam::${local.account_id}:role/github-actions-deploy"

  common_tags = {
    AppName = var.app_name
    Env     = var.env
  }
}

# ─────────────────────────────────────────────
# S3: react-app-bucket-access-logs (created first — needed for logging config)
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "access_logs" {
  bucket = "react-app-bucket-access-logs"
  tags   = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RootFullAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.access_logs.arn,
          "${aws_s3_bucket.access_logs.arn}/*"
        ]
      },
      {
        Sid       = "AllowS3LogDelivery"
        Effect    = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.access_logs.arn}/*"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.react_app.arn
          }
        }
      }
    ]
  })
}

# ─────────────────────────────────────────────
# S3: react-app-bucket (main website bucket)
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "react_app" {
  bucket = "react-app-bucket-${local.account_id}"
  tags   = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "react_app" {
  bucket        = aws_s3_bucket.react_app.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "react-app-bucket/"
}

resource "aws_s3_bucket_website_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  # Depends on public access block being disabled first
  depends_on = [aws_s3_bucket_public_access_block.react_app]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.react_app.arn}/*"
      },
      {
        Sid    = "SmartSimarReadAccess"
        Effect = "Allow"
        Principal = {
          AWS = local.smart_simar_arn
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.react_app.arn,
          "${aws_s3_bucket.react_app.arn}/*"
        ]
      },
      {
        Sid    = "GitHubActionsDeployAccess"
        Effect = "Allow"
        Principal = {
          AWS = local.github_actions_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.react_app.arn,
          "${aws_s3_bucket.react_app.arn}/*"
        ]
      },
      {
        Sid    = "DenyAllOthers"
        Effect = "Deny"
        Principal = "*"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutBucketPolicy",
          "s3:DeleteBucket"
        ]
        Resource = [
          aws_s3_bucket.react_app.arn,
          "${aws_s3_bucket.react_app.arn}/*"
        ]
        Condition = {
          ArnNotLike = {
            "aws:PrincipalArn" = [
              local.smart_simar_arn,
              local.github_actions_role_arn,
              "arn:aws:iam::${local.account_id}:root"
            ]
          }
        }
      }
    ]
  })
}

# ─────────────────────────────────────────────
# CloudFront OAC
# ─────────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "react_app" {
  name                              = "react-app-oac"
  description                       = "OAC for react-app-bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ─────────────────────────────────────────────
# CloudFront Distribution: react-app-cdn
# ─────────────────────────────────────────────

resource "aws_cloudfront_distribution" "react_app_cdn" {
  comment             = "react-app-cdn"
  default_root_object = "main.html"
  enabled             = true
  price_class         = "PriceClass_200"
  tags                = local.common_tags

  origin {
    # REST API (S3 regional) endpoint — required for OAC
    domain_name              = aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id                = "S3-react-app-bucket"
    origin_access_control_id = aws_cloudfront_origin_access_control.react_app.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-react-app-bucket"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ─────────────────────────────────────────────
# IAM OIDC Provider + github-actions-deploy role
# ─────────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:*:ref:refs/heads/main"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "github_actions_permissions" {
  # S3: read + write on react-app-bucket only
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.react_app.arn,
      "${aws_s3_bucket.react_app.arn}/*"
    ]
  }

  # CloudFront: invalidate cache only
  statement {
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.react_app_cdn.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "github-actions-deploy-policy"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
