output "cloudwatch_event_rule_arn" {
  value = aws_cloudwatch_event_rule.eventbridge_rule.arn
}
