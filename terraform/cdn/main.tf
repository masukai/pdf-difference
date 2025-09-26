####################
# S3 for static website
####################
resource "aws_s3_bucket" "hosting" {
  bucket        = "${var.name}-hosting-bucket"
  force_destroy = false
}

# CloudFront用コメントアウト
# resource "aws_s3_bucket_policy" "hosting" {
#   bucket = aws_s3_bucket.hosting.id
#   policy = data.aws_iam_policy_document.hosting.json
# }

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.hosting.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "hosting" {
  bucket = aws_s3_bucket.hosting.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "hosting" {
  bucket = aws_s3_bucket.hosting.id

  block_public_acls       = false # true
  block_public_policy     = false # true
  ignore_public_acls      = false # true
  restrict_public_buckets = false # true
}

# ログ用バケット オブジェクト所有者設定 ACL有効化
resource "aws_s3_bucket_ownership_controls" "hosting_ownership_controls" {
  bucket = aws_s3_bucket.hosting.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# CloudFrontが使えない間、バケットポリシーで公開する(上記もfalseにしてる)
data "aws_iam_policy_document" "hosting_sub" {
  statement { # DenyにするとGitHubから送れないので、手動で後ほど対応。普段はコメントアウト
    sid    = "DefaultDeny"
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.hosting.id}/*"]
    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = var.allow_cidr_blocks
    }
    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }
  statement {
    sid    = "PublicGetObject"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.hosting.id}/*"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }
}

resource "aws_s3_bucket_policy" "hosting_sub" {
  bucket = aws_s3_bucket.hosting.id
  policy = data.aws_iam_policy_document.hosting_sub.json
}

####################
# CloudFront
####################
# resource "aws_cloudfront_distribution" "static_website" {
#   origin {
#     domain_name = aws_s3_bucket.hosting.bucket_regional_domain_name
#     origin_id   = aws_s3_bucket.hosting.id
#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.static_website.cloudfront_access_identity_path
#     }
#   }

#   enabled             = true
#   default_root_object = "index.html"
#   wait_for_deployment = true

#   aliases = [local.docs_domain_name]

#   viewer_certificate {
#     acm_certificate_arn            = local.aws_acm_certificate_arn
#     cloudfront_default_certificate = false
#     minimum_protocol_version       = "TLSv1.2_2019" # SSLの最小バージョン。AWSの推奨値を採用。
#     # SNI(名前ベース)のSSL機能を使用する。
#     # https://aws.amazon.com/jp/cloudfront/custom-ssl-domains/
#     ssl_support_method = "sni-only"
#   }

#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD"]
#     cached_methods         = ["GET", "HEAD"]
#     target_origin_id       = aws_s3_bucket.hosting.id
#     compress               = true
#     viewer_protocol_policy = "redirect-to-https"

#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   web_acl_id = aws_wafv2_web_acl.static_website.arn
# }

# resource "aws_cloudfront_origin_access_identity" "static_website" {
#   comment = "access-identity-static-web-site.s3.amazonaws.com"
# }

####################
# WAF for restrict IP
####################
# provider "aws" {
#   alias                    = "virginia"
#   region                   = "us-east-1"
#   profile                  = "voc"
#   shared_credentials_files = ["~/.aws/credentials"]

#   default_tags {
#     tags = {
#       CreatedBy = "Terraform"
#     }
#   }
# }

# resource "aws_wafv2_ip_set" "static_website" {
#   provider           = aws.virginia
#   name               = "${var.name}-docs-waf"
#   description        = "IP set by terraform."
#   scope              = "CLOUDFRONT"
#   ip_address_version = "IPV4"
#   addresses          = var.allow_cidr_blocks
# }

# resource "aws_wafv2_web_acl" "static_website" {
#   provider = aws.virginia
#   name     = "${var.name}-docs-waf"
#   scope    = "CLOUDFRONT"
#   default_action {
#     block {}
#   }
#   rule {
#     name     = "AllowIPList"
#     priority = 1
#     action {
#       allow {}
#     }
#     statement {
#       ip_set_reference_statement {
#         arn = aws_wafv2_ip_set.static_website.arn
#       }
#     }
#     visibility_config {
#       cloudwatch_metrics_enabled = false
#       metric_name                = "AllowIPList"
#       sampled_requests_enabled   = false
#     }
#   }
#   visibility_config {
#     cloudwatch_metrics_enabled = false
#     metric_name                = "waf_webacl_metric"
#     sampled_requests_enabled   = false
#   }
# }
