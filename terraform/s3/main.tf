# S3 データの保存先
resource "aws_s3_bucket" "main" {
  bucket        = "${var.name}-bucket"
  force_destroy = false
}

module "distribution_files" {
  source   = "hashicorp/dir/template" # 固定
  base_dir = "../dist"                # ファイルを読み取るディレクトリ
}

resource "aws_s3_object" "main_input_before_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "01-pdf-file-before/"
}

resource "aws_s3_object" "main_input_after_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "02-pdf-file-after/"
}

resource "aws_s3_object" "main_output_blue_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "result/output-file-blue/"
}

resource "aws_s3_object" "main_output_green_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "result/output-file-green/"
}

resource "aws_s3_object" "main_output_red_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "result/output-file-red/"
}

resource "aws_s3_object" "main_input_asset_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "asset/"
}

resource "aws_s3_object" "main_input_status_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "status/"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.main.bucket
  eventbridge = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false # true
  block_public_policy     = false # true
  ignore_public_acls      = false # true
  restrict_public_buckets = false # true
}

# ログ用バケット オブジェクト所有者設定 ACL有効化
resource "aws_s3_bucket_ownership_controls" "main_ownership_controls" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# CloudFrontが使えない間、バケットポリシーで公開する(上記もfalseにしてる)
data "aws_iam_policy_document" "main_sub" {
  # statement { # DenyにするとRestAPIが送れなくなるので、今後対応&会社にいるとPDFを送れなくなる
  #   sid    = "DefaultDeny"
  #   effect = "Deny"
  #   actions = [
  #     "s3:*"
  #   ]
  #   resources = ["arn:aws:s3:::${aws_s3_bucket.main.id}/*"]
  #   condition {
  #     test     = "NotIpAddress"
  #     variable = "aws:SourceIp"
  #     values   = var.allow_cidr_blocks
  #   }
  #   principals {
  #     identifiers = ["*"]
  #     type        = "*"
  #   }
  # }
  statement {
    sid    = "PublicGetObject"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.main.id}/*"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
  }
}

resource "aws_s3_bucket_policy" "main_sub" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main_sub.json
}
