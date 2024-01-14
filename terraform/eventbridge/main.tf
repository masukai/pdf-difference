resource "aws_cloudwatch_event_rule" "eventbridge_rule" {
  name        = "${var.name}-event-role"
  description = "${var.name} event role"
  event_pattern = jsonencode({
    "detail-type" : ["Object Created"],
    "source" : ["aws.s3"],
    "detail" : {
      "bucket" : {
        "name" : [var.bucket_input_name]
      },
      "object" : {
        "key" : [{
          "prefix" : "after-file/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "eventbridge_rule" {
  rule = aws_cloudwatch_event_rule.eventbridge_rule.name

  arn = var.lambda_function_arn
  input_transformer {
    input_paths = {
      "input_bucket_name" : "$.detail.bucket.name",
      "input_s3_key" : "$.detail.object.key"
    }
    input_template = <<TEMPLATE
{"Parameters": {"input_bucket_name":"<input_bucket_name>", "input_s3_key":"<input_s3_key>"}}
    TEMPLATE
  }
}
