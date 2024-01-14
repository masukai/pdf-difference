output "bucket_input_name" {
  value = aws_s3_bucket.main_input.bucket
}

output "bucket_output_name" {
  value = aws_s3_bucket.main_output.bucket
}
