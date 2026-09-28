output "launch_template_id" {
  value = aws_launch_template.app.id
}

output "launch_template_latest_version" {
  description = "Consumed by the autoscaling module so the ASG always launches the newest template revision."
  value       = aws_launch_template.app.latest_version
}
