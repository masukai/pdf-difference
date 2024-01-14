data "aws_iam_policy_document" "eventbridge_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eventbridge_service_role" {
  name               = "${var.name}-eventbridge-service-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_policy.json
}
