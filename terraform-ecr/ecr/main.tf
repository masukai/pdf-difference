resource "aws_ecr_repository" "lambda-python" {
  name = "${var.name}-lambda-python"
}
