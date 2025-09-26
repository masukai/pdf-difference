terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.29.0"
    }
  }

  backend "local" {}
}

provider "aws" {
  profile                  = "pdf-difference"
  region                   = "ap-northeast-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

module "s3" {
  source = "./s3"

  name              = local.name
  allow_cidr_blocks = local.allow_cidr_blocks
}

module "lambda" {
  source = "./lambda"

  name                               = local.name
  cloudwatch_event_rule_arn          = module.eventbridge.cloudwatch_event_rule_arn
  bucket_name                        = module.s3.bucket_name
  ecr_repository_uri                 = local.ecr_repository_uri
  aws_api_gateway_rest_api_before_id = module.apigateway.aws_api_gateway_rest_api_before_id
  aws_api_gateway_rest_api_after_id  = module.apigateway.aws_api_gateway_rest_api_after_id
}

module "eventbridge" {
  source = "./eventbridge"

  name                     = local.name
  lambda_function_arn      = module.lambda.lambda_function_arn
  bucket_name              = module.s3.bucket_name
  bucket_input_folder_name = module.s3.bucket_input_folder_name
}

module "apigateway" {
  source = "./apigateway"

  name                                  = local.name
  lambda_front_upload_before_invoke_arn = module.lambda.lambda_front_upload_before_invoke_arn
  lambda_front_upload_after_invoke_arn  = module.lambda.lambda_front_upload_after_invoke_arn
  s3_hosting_bucket_name                = module.cdn.s3_hosting_bucket_name
}

module "cdn" {
  source = "./cdn"

  name              = local.name
  allow_cidr_blocks = local.allow_cidr_blocks
}
