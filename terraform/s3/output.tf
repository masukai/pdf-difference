output "bucket_input_name" {
  value = aws_s3_bucket.main_input.bucket
}

output "bucket_output_name" {
  value = aws_s3_bucket.main_output.bucket
}

output "bucket_input_folder_name" {
  value = aws_s3_object.main_after_input_folder.key
}
