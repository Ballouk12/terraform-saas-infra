output "topic_arn" {
  description = "Consumed by the cloudwatch module as the alarm_actions target."
  value       = aws_sns_topic.alerts.arn
}
