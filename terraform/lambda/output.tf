output "lambda_function_arn" {
  value = aws_lambda_function.lambda_function.arn
}

output "lambda_front_upload_before_invoke_arn" {
  value = aws_lambda_function.lambda_front_upload_before.invoke_arn
}

output "lambda_front_upload_after_invoke_arn" {
  value = aws_lambda_function.lambda_front_upload_after.invoke_arn
}
