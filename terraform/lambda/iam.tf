data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "assume_role" {
  name               = "${var.name}-lambda-assume-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy" "iam_policy_AWSLambdaBasicExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "iam_policy_AWSLambdaBasicExecutionRole" {
  name   = "${var.name}-lambda-function-role"
  policy = data.aws_iam_policy.iam_policy_AWSLambdaBasicExecutionRole.policy
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.assume_role.name
  policy_arn = aws_iam_policy.iam_policy_AWSLambdaBasicExecutionRole.arn
}

data "aws_iam_policy_document" "allow_access_s3_role_policy" {
  statement {
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "allow_access_s3" {
  name   = "test_s3_policy"
  policy = data.aws_iam_policy_document.allow_access_s3_role_policy.json
}

resource "aws_iam_role_policy_attachment" "test_s3" {
  role       = aws_iam_role.assume_role.name
  policy_arn = aws_iam_policy.allow_access_s3.arn
}
