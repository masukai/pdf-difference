# S3 データの保存先(input)
resource "aws_s3_bucket" "main_input" {
  bucket        = "${var.name}-input-bucket"
  force_destroy = false
}

resource "aws_s3_object" "main_before_input_folder" {
  bucket = aws_s3_bucket.main_input.id
  key    = "pdf-file-before/"
}

resource "aws_s3_object" "main_after_input_folder" {
  bucket = aws_s3_bucket.main_input.id
  key    = "pdf-file-after/"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.main_input.bucket
  eventbridge = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main_input" {
  bucket = aws_s3_bucket.main_input.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main_input" {
  bucket = aws_s3_bucket.main_input.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 データの出力先(output)
resource "aws_s3_bucket" "main_output" {
  bucket        = "${var.name}-output-bucket"
  force_destroy = false
}

resource "aws_s3_object" "main_output_blue_folder" {
  bucket = aws_s3_bucket.main_output.id
  key    = "output-file-blue/"
}

resource "aws_s3_object" "main_output_green_folder" {
  bucket = aws_s3_bucket.main_output.id
  key    = "output-file-green/"
}

resource "aws_s3_object" "main_output_red_folder" {
  bucket = aws_s3_bucket.main_output.id
  key    = "output-file-red/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main_output" {
  bucket = aws_s3_bucket.main_output.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main_output" {
  bucket = aws_s3_bucket.main_output.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
