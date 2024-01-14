data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = "${var.name}-lambda-function"
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  filename         = data.archive_file.lambda_function_zip.output_path
  source_code_hash = data.archive_file.lambda_function_zip.output_base64sha256
  role             = aws_iam_role.assume_role.arn
  timeout          = 120
  memory_size      = 1024

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }

  environment {
    variables = {
      "VAR_NAME" = var.name
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "lambda_function" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.cloudwatch_event_rule_arn
}
