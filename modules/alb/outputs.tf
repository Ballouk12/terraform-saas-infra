output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "Used by CloudWatch alarms (e.g. RequestCount, HTTPCode_Target_5XX_Count dimensions)."
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "Consumed by the route53 module to create the alias record."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Consumed by the route53 module's alias record (zone_id argument)."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "Consumed by the autoscaling module to attach instances."
  value       = aws_lb_target_group.app.arn
}

output "target_group_arn_suffix" {
  description = "Used by CloudWatch alarms."
  value       = aws_lb_target_group.app.arn_suffix
}
