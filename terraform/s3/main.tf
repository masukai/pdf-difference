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

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
