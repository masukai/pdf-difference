# Variables
ENV_NAME = "pdf-difference"
DOCUMENT_OUTPUT_PATH = "dist"
DOCUMENT_BUCKET_NAME = "pdf-difference-hosting-bucket"
IMAGE_OUTPUT_PATH = "asset"
IMAGE_BUCKET_NAME = "pdf-difference-bucket"

.PHONY: help ## Help
help:
	 @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: upload-front
upload-front: ## Upload HTML Documents for S3
	aws s3 sync $(DOCUMENT_OUTPUT_PATH) s3://$(DOCUMENT_BUCKET_NAME)/ --exclude "*.DS_Store*"

.PHONY: upload-status
upload-status: ## Upload images for S3
	aws s3 sync $(IMAGE_OUTPUT_PATH) s3://$(IMAGE_BUCKET_NAME)/asset/ --exclude "*.DS_Store*"

.PHONY: lambda-push
lambda-push: ## Push from ECR to Lambda
	aws lambda update-function-code --function-name $(ENV_NAME)-lambda-function --image-uri ************.dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV_NAME)-lambda-python:latest
