# webブラウザからs3のbeforeフォルダにアップロードするLambda
resource "aws_api_gateway_rest_api" "before_api" {
  name = "${var.name}-before-api"
  binary_media_types = [
    "multipart/form-data",
  ]
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "before_resource" {
  depends_on  = [aws_api_gateway_rest_api.before_api]
  path_part   = "fileUploader"
  parent_id   = aws_api_gateway_rest_api.before_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.before_api.id
}

resource "aws_api_gateway_method" "before_options" {
  rest_api_id   = aws_api_gateway_rest_api.before_api.id
  resource_id   = aws_api_gateway_resource.before_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "before_options" {
  rest_api_id = aws_api_gateway_rest_api.before_api.id
  resource_id = aws_api_gateway_resource.before_resource.id
  http_method = aws_api_gateway_method.before_options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "before_options" {
  rest_api_id = aws_api_gateway_rest_api.before_api.id
  resource_id = aws_api_gateway_resource.before_resource.id
  http_method = aws_api_gateway_method.before_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "before_options" {
  rest_api_id = aws_api_gateway_rest_api.before_api.id
  resource_id = aws_api_gateway_resource.before_resource.id
  http_method = aws_api_gateway_method.before_options.http_method
  status_code = aws_api_gateway_method_response.before_options.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'http://${var.s3_hosting_bucket_name}.s3-website-ap-northeast-1.amazonaws.com', 'https://${var.s3_hosting_bucket_name}.s3.ap-northeast-1.amazonaws.com', 'http://172.20.207.40'" # S3の静的ホスティングサイト
  }
}

resource "aws_api_gateway_method" "before_method" {
  depends_on    = [aws_api_gateway_resource.before_resource]
  rest_api_id   = aws_api_gateway_rest_api.before_api.id
  resource_id   = aws_api_gateway_resource.before_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "before_integration" {
  depends_on              = [aws_api_gateway_method.before_method]
  rest_api_id             = aws_api_gateway_rest_api.before_api.id
  resource_id             = aws_api_gateway_resource.before_resource.id
  http_method             = aws_api_gateway_method.before_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = var.lambda_front_upload_before_invoke_arn
  request_templates = { # Not documented
    "multipart/form-data" = "${trimspace(file("./apigateway/mapping.template"))}"
  }
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  content_handling     = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_integration_response" "before_integration_response" {
  depends_on = [
    aws_api_gateway_integration.before_integration,
    aws_api_gateway_method_response.before_response_200
  ]
  rest_api_id = aws_api_gateway_rest_api.before_api.id
  resource_id = aws_api_gateway_resource.before_resource.id
  http_method = aws_api_gateway_method.before_method.http_method
  status_code = aws_api_gateway_method_response.before_response_200.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
EOF
  }
}

resource "aws_api_gateway_method_response" "before_response_200" {
  depends_on  = [aws_api_gateway_method.before_method]
  rest_api_id = aws_api_gateway_rest_api.before_api.id
  resource_id = aws_api_gateway_resource.before_resource.id
  http_method = aws_api_gateway_method.before_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_deployment" "before_deployment" {
  depends_on = [
    aws_api_gateway_integration.before_integration,
    aws_api_gateway_integration_response.before_integration_response,
  ]
  rest_api_id = aws_api_gateway_rest_api.before_api.id
  triggers = {
    # resource "aws_lambda_function" の内容が変わるごとにデプロイされるようにする
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.before_api,
      aws_api_gateway_resource.before_resource.id,
      aws_api_gateway_method.before_method.id,
      aws_api_gateway_integration.before_integration.id,
    ]))
  }
}

resource "aws_api_gateway_stage" "before_stage" {
  depends_on    = [aws_api_gateway_deployment.before_deployment]
  deployment_id = aws_api_gateway_deployment.before_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.before_api.id
  stage_name    = "prod"
}

# webブラウザからs3のafterフォルダにアップロードするLambda
resource "aws_api_gateway_rest_api" "after_api" {
  name = "${var.name}-after-api"
  binary_media_types = [
    "multipart/form-data",
  ]
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "after_resource" {
  depends_on  = [aws_api_gateway_rest_api.after_api]
  path_part   = "fileUploader"
  parent_id   = aws_api_gateway_rest_api.after_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.after_api.id
}

resource "aws_api_gateway_method" "after_options" {
  rest_api_id   = aws_api_gateway_rest_api.after_api.id
  resource_id   = aws_api_gateway_resource.after_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "after_options" {
  rest_api_id = aws_api_gateway_rest_api.after_api.id
  resource_id = aws_api_gateway_resource.after_resource.id
  http_method = aws_api_gateway_method.after_options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration" "after_options" {
  rest_api_id = aws_api_gateway_rest_api.after_api.id
  resource_id = aws_api_gateway_resource.after_resource.id
  http_method = aws_api_gateway_method.after_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "after_options" {
  rest_api_id = aws_api_gateway_rest_api.after_api.id
  resource_id = aws_api_gateway_resource.after_resource.id
  http_method = aws_api_gateway_method.after_options.http_method
  status_code = aws_api_gateway_method_response.after_options.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'http://${var.s3_hosting_bucket_name}.s3-website-ap-northeast-1.amazonaws.com', 'https://${var.s3_hosting_bucket_name}.s3.ap-northeast-1.amazonaws.com', 'http://172.20.207.40'" # S3の静的ホスティングサイト
  }
}

resource "aws_api_gateway_method" "after_method" {
  depends_on    = [aws_api_gateway_resource.after_resource]
  rest_api_id   = aws_api_gateway_rest_api.after_api.id
  resource_id   = aws_api_gateway_resource.after_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "after_integration" {
  depends_on              = [aws_api_gateway_method.after_method]
  rest_api_id             = aws_api_gateway_rest_api.after_api.id
  resource_id             = aws_api_gateway_resource.after_resource.id
  http_method             = aws_api_gateway_method.after_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = var.lambda_front_upload_after_invoke_arn
  request_templates = { # Not documented
    "multipart/form-data" = "${trimspace(file("./apigateway/mapping.template"))}"
  }
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  content_handling     = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_integration_response" "after_integration_response" {
  depends_on = [
    aws_api_gateway_integration.after_integration,
    aws_api_gateway_method_response.after_response_200
  ]
  rest_api_id = aws_api_gateway_rest_api.after_api.id
  resource_id = aws_api_gateway_resource.after_resource.id
  http_method = aws_api_gateway_method.after_method.http_method
  status_code = aws_api_gateway_method_response.after_response_200.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
EOF
  }
}

resource "aws_api_gateway_method_response" "after_response_200" {
  depends_on  = [aws_api_gateway_method.after_method]
  rest_api_id = aws_api_gateway_rest_api.after_api.id
  resource_id = aws_api_gateway_resource.after_resource.id
  http_method = aws_api_gateway_method.after_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_deployment" "after_deployment" {
  depends_on = [
    aws_api_gateway_integration.after_integration,
    aws_api_gateway_integration_response.after_integration_response,
  ]
  rest_api_id = aws_api_gateway_rest_api.after_api.id
  triggers = {
    # resource "aws_lambda_function" の内容が変わるごとにデプロイされるようにする
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.after_api,
      aws_api_gateway_resource.after_resource.id,
      aws_api_gateway_method.after_method.id,
      aws_api_gateway_integration.after_integration.id,
    ]))
  }
}

resource "aws_api_gateway_stage" "after_stage" {
  depends_on    = [aws_api_gateway_deployment.after_deployment]
  deployment_id = aws_api_gateway_deployment.after_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.after_api.id
  stage_name    = "prod"
}
