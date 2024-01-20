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

  name = local.name
}

module "lambda" {
  source = "./lambda"

  name                      = local.name
  cloudwatch_event_rule_arn = module.eventbridge.cloudwatch_event_rule_arn
  bucket_name               = module.s3.bucket_name
}

module "eventbridge" {
  source = "./eventbridge"

  name                     = local.name
  lambda_function_arn      = module.lambda.lambda_function_arn
  bucket_name              = module.s3.bucket_name
  bucket_input_folder_name = module.s3.bucket_input_folder_name
}
