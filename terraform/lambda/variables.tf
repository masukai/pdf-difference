variable "name" {
  type = string
}

variable "cloudwatch_event_rule_arn" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "ecr_repository_uri" {
  type = string
}

variable "aws_api_gateway_rest_api_before_id" {
  type = string
}

variable "aws_api_gateway_rest_api_after_id" {
  type = string
}
