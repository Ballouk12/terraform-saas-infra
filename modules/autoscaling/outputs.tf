output "asg_name" {
  description = "Consumed by the cloudwatch module for CPU/health alarms."
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  value = aws_autoscaling_group.app.arn
}
