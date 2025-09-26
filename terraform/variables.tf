locals {
  allow_cidr_blocks = [
    "999.999.999.999/32",
  ]
  name               = "pdf-difference"
  ecr_repository_uri = "************.dkr.ecr.ap-northeast-1.amazonaws.com/pdf-difference-lambda-python:latest"
}
