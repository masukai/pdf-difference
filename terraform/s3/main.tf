# S3 データの保存先
resource "aws_s3_bucket" "main" {
  bucket        = "${var.name}-bucket"
  force_destroy = false
}

module "distribution_files" {
  source   = "hashicorp/dir/template" # 固定
  base_dir = "../dist"                # ファイルを読み取るディレクトリ
}

resource "aws_s3_object" "main_hosting" {
  for_each     = module.distribution_files.files
  bucket       = aws_s3_bucket.main.id
  key          = each.key
  source       = each.value.source_path
  content_type = each.value.content_type
  etag         = filemd5(each.value.source_path)
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

resource "aws_s3_object" "main_input_before_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "pdf-file-before/"
}

resource "aws_s3_object" "main_input_after_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "pdf-file-after/"
}

resource "aws_s3_object" "main_output_blue_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "output-file-blue/"
}

resource "aws_s3_object" "main_output_green_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "output-file-green/"
}

resource "aws_s3_object" "main_output_red_folder" {
  bucket = aws_s3_bucket.main.id
  key    = "output-file-red/"
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

  block_public_acls       = false #true
  block_public_policy     = false #true
  ignore_public_acls      = false #true
  restrict_public_buckets = false #true
}
