output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "app_url" {
  value = "https://${module.route53.record_fqdn}"
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_secret_arn" {
  description = "Fetch DB credentials at runtime: aws secretsmanager get-secret-value --secret-id <this arn>"
  value       = module.rds.secret_arn
}

output "redis_primary_endpoint" {
  value = module.elasticache.primary_endpoint_address
}

output "media_bucket" {
  value = module.s3_media.bucket_id
}

output "backups_bucket" {
  value = module.s3_backups.bucket_id
}

output "app_ecr_repository_url" {
  value = module.ecr.repository_url
}

output "app_version_parameter_name" {
  value = module.app_config.parameter_name
}

output "app_asg_name" {
  value = module.autoscaling.asg_name
}
