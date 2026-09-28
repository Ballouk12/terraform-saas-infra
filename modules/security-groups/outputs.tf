output "alb_security_group_id" {
  description = "SG attached to the ALB. Consumed by the alb module."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "SG attached to EC2/Kubernetes worker nodes. Consumed by the ec2 module."
  value       = aws_security_group.app.id
}

output "rds_security_group_id" {
  description = "SG attached to the RDS instance. Consumed by the rds module."
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "SG attached to the ElastiCache Redis cluster. Consumed by the elasticache module."
  value       = aws_security_group.redis.id
}
