output "bucket_name" {
  value = aws_s3_bucket.main.bucket
}

output "bucket_input_folder_name" {
  value = aws_s3_object.main_input_after_folder.key
}
