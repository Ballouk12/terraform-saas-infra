output "db_instance_id" {
  value = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "host:port endpoint the Spring Boot backend connects to."
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "secret_arn" {
  description = "Secrets Manager ARN holding username/password. The app should read credentials from here at runtime (e.g. via IAM-scoped GetSecretValue), never from Terraform state or env vars checked into code."
  value       = aws_secretsmanager_secret.db_credentials.arn
}
