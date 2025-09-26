####################
# S3 for static website
####################
# data "aws_iam_policy_document" "hosting" {
#   policy_id = "PolicyForBucketIpAccess"
#   statement {
#     sid     = "IPAllow"
#     actions = ["s3:GetObject"]
#     effect  = "Allow"
#     resources = [
#       "${aws_s3_bucket.hosting.arn}",
#       "${aws_s3_bucket.hosting.arn}/*",
#     ]
#     principals {
#       type        = "AWS"
#       identifiers = [aws_cloudfront_origin_access_identity.static_website.iam_arn]
#     }
#   }
# }
