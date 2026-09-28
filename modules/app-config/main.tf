locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "app-config"
  })
}

resource "aws_ssm_parameter" "app_version" {
  name        = var.parameter_name
  description = "Application image tag consumed by EC2 User Data"
  type        = "String"
  value       = var.initial_app_version

  lifecycle {
    ignore_changes = [value]
  }

  tags = local.common_tags
}
