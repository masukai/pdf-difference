# S3に入ったファイルを処理するLambda
resource "aws_lambda_function" "lambda_function" {
  depends_on    = [aws_iam_role.assume_role]
  function_name = "${var.name}-lambda-function"
  role          = aws_iam_role.assume_role.arn
  package_type  = "Image"
  image_uri     = var.ecr_repository_uri
  timeout       = 300
  memory_size   = 1024

  lifecycle {
    ignore_changes = [image_uri]
  }

  ephemeral_storage {
    size = 2048 # Min 512 MB and the Max 10240 MB
  }
}

resource "aws_lambda_function_event_invoke_config" "main" {
  function_name          = aws_lambda_function.lambda_function.function_name
  maximum_retry_attempts = 0
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

# リージョンと環境の情報の取得
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# webブラウザからs3のbeforeフォルダにアップロードするLambda
data "archive_file" "upload_before_zip" {
  type        = "zip"
  source_dir  = "lambda_function/upload_before"
  output_path = "lambda_function/upload_before.zip"
}

resource "aws_lambda_function" "lambda_front_upload_before" {
  depends_on       = [aws_iam_role.assume_role]
  function_name    = "${var.name}-lambda-front-upload-before"
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.upload_before_zip.output_path
  source_code_hash = data.archive_file.upload_before_zip.output_base64sha256
  role             = aws_iam_role.assume_role.arn
  timeout          = 30
}

resource "aws_cloudwatch_log_group" "lambda_front_upload_before_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_front_upload_before.function_name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "lambda_front_upload_before" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_front_upload_before.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.aws_api_gateway_rest_api_before_id}/*/POST/fileUploader" # 一部ハードコード
}

# webブラウザからs3のafterフォルダにアップロードするLambda
data "archive_file" "upload_after_zip" {
  type        = "zip"
  source_dir  = "lambda_function/upload_after"
  output_path = "lambda_function/upload_after.zip"
}

resource "aws_lambda_function" "lambda_front_upload_after" {
  depends_on       = [aws_iam_role.assume_role]
  function_name    = "${var.name}-lambda-front-upload-after"
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.upload_after_zip.output_path
  source_code_hash = data.archive_file.upload_after_zip.output_base64sha256
  role             = aws_iam_role.assume_role.arn
  timeout          = 30
}

resource "aws_cloudwatch_log_group" "lambda_front_upload_after_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_front_upload_after.function_name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "lambda_front_upload_after" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_front_upload_after.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.aws_api_gateway_rest_api_after_id}/*/POST/fileUploader" # 一部ハードコード
}
