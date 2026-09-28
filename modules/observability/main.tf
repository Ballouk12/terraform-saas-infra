locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "observability"
  })
}

resource "aws_prometheus_workspace" "amp" {
  alias = "${local.name_prefix}-amp"
  tags  = local.common_tags
}

resource "aws_iam_role" "grafana_workspace" {
  name = "${local.name_prefix}-grafana-workspace-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "grafana.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "grafana_workspace" {
  name = "${local.name_prefix}-grafana-workspace-policy"
  role = aws_iam_role.grafana_workspace.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "aps:DescribeWorkspace",
        "aps:QueryMetrics",
        "aps:GetMetricMetadata",
        "aps:GetSeries",
        "aps:GetLabels"
      ]
      Resource = aws_prometheus_workspace.amp.arn
    }]
  })
}

resource "aws_grafana_workspace" "grafana" {
  name                     = "${local.name_prefix}-amg"
  account_access_type      = "CURRENT_ACCOUNT"
  role_arn                 = aws_iam_role.grafana_workspace.arn
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["PROMETHEUS"]

  vpc_configuration {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.grafana.id]
  }

  tags = local.common_tags
}

resource "aws_grafana_workspace_api_key" "grafana" {
  workspace_id    = aws_grafana_workspace.grafana.id
  key_name        = "${local.name_prefix}-terraform"
  key_role        = "ADMIN"
  seconds_to_live = 86400
}

resource "aws_secretsmanager_secret" "grafana_api_key" {
  name                    = "${local.name_prefix}-grafana-api-key"
  description             = "AWS Managed Grafana API key for Terraform provisioning"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "grafana_api_key" {
  secret_id     = aws_secretsmanager_secret.grafana_api_key.id
  secret_string = aws_grafana_workspace_api_key.grafana.key
}

resource "aws_iam_role_policy" "ec2_amp_remote_write" {
  name = "${local.name_prefix}-ec2-amp-policy"
  role = var.ec2_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:DescribeWorkspace"
        ]
        Resource = aws_prometheus_workspace.amp.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_security_group" "grafana" {
  name        = "${local.name_prefix}-grafana-sg"
  description = "Managed Grafana VPC access for internal resources"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = local.common_tags
}


