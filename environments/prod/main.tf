locals {
  tags = {
    Owner = "platform-team"
  }
}

moved {
  from = module.ec2.aws_ssm_parameter.this
  to   = module.app_config.aws_ssm_parameter.app_version
}

############################################
# Networking
############################################
module "vpc" {
  source = "../../modules/vpc"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zone_count = var.availability_zone_count
  single_nat_gateway      = false # prod: one NAT per AZ for true HA
  enable_flow_logs        = true
  tags                    = local.tags
}

############################################
# Security
############################################
module "security_groups" {
  source = "../../modules/security-groups"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
  tags           = local.tags
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.tags
}

module "app_config" {
  source = "../../modules/app-config"

  project_name        = var.project_name
  environment         = var.environment
  parameter_name      = "/${var.environment}/${var.project_name}/app/version"
  initial_app_version = var.initial_app_version
  tags                = local.tags
}

module "iam" {
  source = "../../modules/iam"

  project_name              = var.project_name
  environment               = var.environment
  s3_bucket_arns            = [module.s3_media.bucket_arn]
  ecr_repository_arn        = module.ecr.repository_arn
  app_version_parameter_arn = module.app_config.parameter_arn
  tags                      = local.tags
}

############################################
# Storage
############################################
module "s3_media" {
  source = "../../modules/s3"

  project_name   = var.project_name
  environment    = var.environment
  bucket_purpose = "media"
  tags           = local.tags
}

module "s3_backups" {
  source = "../../modules/s3"

  project_name   = var.project_name
  environment    = var.environment
  bucket_purpose = "backups"
  tags           = local.tags
}

############################################
# Compute
############################################
module "ec2" {
  source = "../../modules/ec2"

  project_name              = var.project_name
  environment               = var.environment
  os                        = var.os
  instance_type             = var.app_instance_type
  key_name                  = var.key_name
  iam_instance_profile_name = module.iam.instance_profile_name
  security_group_ids        = [module.security_groups.app_security_group_id]
  user_data = base64encode(templatefile("${path.module}/../../modules/cloudwatch/cloudwatch-agent-user-data.sh.tpl", {
    aws_region         = var.aws_region
    log_group_name     = "/binaitech/${var.environment}/app"
    ecr_repository_url = module.ecr.repository_url
    ssm_parameter_name = module.app_config.parameter_name
    container_name     = var.app_container_name
    container_port     = var.app_port
  }))
  tags = local.tags
}

module "autoscaling" {
  source = "../../modules/autoscaling"

  project_name            = var.project_name
  environment             = var.environment
  launch_template_id      = module.ec2.launch_template_id
  launch_template_version = module.ec2.launch_template_latest_version
  private_subnet_ids      = module.vpc.private_subnet_ids
  target_group_arns       = [module.alb.target_group_arn]
  min_size                = var.asg_min_size
  max_size                = var.asg_max_size
  desired_capacity        = var.asg_desired_capacity
  instance_warmup         = var.instance_warmup
  min_healthy_percentage  = var.min_healthy_percentage
  auto_rollback           = var.auto_rollback
  tags                    = local.tags
}

############################################
# Load Balancing
############################################
module "alb" {
  source = "../../modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  acm_certificate_arn   = var.acm_certificate_arn
  app_port              = var.app_port
  tags                  = local.tags
}

############################################
# Database & Cache
############################################
module "rds" {
  source = "../../modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  db_subnet_group_name   = module.vpc.db_subnet_group_name
  vpc_security_group_ids = [module.security_groups.rds_security_group_id]
  db_username            = var.db_username
  multi_az               = true # prod: synchronous standby for automatic failover
  deletion_protection    = true
  skip_final_snapshot    = false
  tags                   = local.tags
}

module "elasticache" {
  source = "../../modules/elasticache"

  project_name               = var.project_name
  environment                = var.environment
  subnet_group_name          = module.vpc.elasticache_subnet_group_name
  security_group_ids         = [module.security_groups.redis_security_group_id]
  num_cache_clusters         = 3 # prod: primary + 2 replicas across AZs
  automatic_failover_enabled = true
  tags                       = local.tags
}

############################################
# DNS
############################################
module "route53" {
  source = "../../modules/route53"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  record_name  = "app"
  create_zone  = true # prod owns the hosted zone; dev/staging add records into it via a data lookup
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
  tags         = local.tags
}

############################################
# Observability & Alerting
############################################
module "sns" {
  source = "../../modules/sns"

  project_name = var.project_name
  environment  = var.environment
  alert_emails = var.alert_emails
  tags         = local.tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name               = var.project_name
  environment                = var.environment
  sns_topic_arn              = module.sns.topic_arn
  asg_name                   = module.autoscaling.asg_name
  alb_arn_suffix             = module.alb.alb_arn_suffix
  target_group_arn_suffix    = module.alb.target_group_arn_suffix
  rds_instance_id            = module.rds.db_instance_id
  redis_replication_group_id = "${var.project_name}-${var.environment}-redis"
  tags                       = local.tags
}
