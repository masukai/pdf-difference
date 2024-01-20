resource "aws_s3_bucket_policy" "deny_ip" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.deny_ip.json
}

data "aws_iam_policy_document" "deny_ip" {
  statement {
    sid       = "S3DenyPolicy"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.main.id}/*"]
    effect    = "Deny"
    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values = [
        "210.170.108.134/32",
        "210.170.108.133/32",
        "208.127.111.92/32",
        "208.127.111.93/32",
        "137.83.213.162"
      ]
    }
  }
}
