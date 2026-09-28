locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "security-groups"
  })
}

############################################
# ALB Security Group — the only SG open to the internet
############################################
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allows inbound HTTP/HTTPS from the internet; forwards only to the app tier."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet (redirected to HTTPS at the listener level)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow ALB to reach app tier on any port (restricted further by the app SG s own ingress rule)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-alb-sg" })
}

############################################
# App / Kubernetes worker node Security Group
# Only reachable from the ALB — never directly from the internet.
############################################
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "App tier (EC2 / Kubernetes worker nodes). Only reachable from the ALB, plus optional SSH from trusted CIDRs."
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  dynamic "ingress" {
    for_each = length(var.allowed_ssh_cidrs) > 0 ? [1] : []
    content {
      description = "SSH from explicitly trusted CIDRs only (prefer SSM Session Manager over this)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidrs
    }
  }

  egress {
    description = "App instances need outbound internet (via NAT) for package pulls, container images, AWS API calls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-app-sg" })
}

############################################
# RDS Security Group — only reachable from the app tier
############################################
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "MySQL access restricted to the app security group only No CIDR based rules group to group only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from app tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "RDS doesnt need general outbound; restricted to VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-rds-sg" })
}

############################################
# ElastiCache Redis Security Group — only reachable from the app tier
############################################
resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Redis access restricted to the app security group only."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from app tier only"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Restricted to VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redis-sg" })
}
