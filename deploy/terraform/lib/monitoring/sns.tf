resource "aws_sns_topic" "monitoring_alerts" {
  name         = "${var.environment_name}-monitoring-alerts"
  display_name = "Retail store sample app monitoring alerts"
  tags         = var.tags
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = "igorrosp@gmail.com"
}
