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

module "github" {
  source = "./github"

  name = local.name
}

module "ecr" {
  source = "./ecr"

  name = local.name
}
