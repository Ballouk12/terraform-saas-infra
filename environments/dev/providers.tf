provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# provider "grafana" {
#   url             = module.observability.grafana_endpoint
#   auth            = module.observability.grafana_api_key
#   tls_skip_verify = true
# }
