resource "aws_lambda_function" "lambda_function" {
  function_name = "${var.name}-lambda-function"
  role          = aws_iam_role.assume_role.arn
  package_type  = "Image"
  image_uri     = "041968548333.dkr.ecr.ap-northeast-1.amazonaws.com/pdf-difference-lambda-python:latest" # ハードコード
  timeout       = 120
  memory_size   = 1024

  lifecycle {
    ignore_changes = [image_uri]
  }

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
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
