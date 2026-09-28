locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "cloudwatch"
  })
}

############################################
# Application log group (shipped from EC2 via CloudWatch agent,
# using the CloudWatchAgentServerPolicy attached in the iam module)
############################################
resource "aws_cloudwatch_log_group" "app" {
  name              = "/binaitech/${var.environment}/app"
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

############################################
# ASG / EC2 alarms
############################################
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${local.name_prefix}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "Sustained high CPU across the app Auto Scaling Group — investigate load or a runaway process; the target-tracking policy should already be scaling out."
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = local.common_tags
}

############################################
# ALB alarms
############################################
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "Elevated server-error rate from app targets — likely an application-level fault, not infrastructure capacity."
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${local.name_prefix}-alb-target-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = var.alb_latency_threshold_seconds
  alarm_description   = "App response time degraded — the 'Low latency' business requirement is at risk."
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = local.common_tags
}

############################################
# RDS alarms
############################################
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${local.name_prefix}-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_free_storage_threshold_bytes
  alarm_description   = "RDS free storage running low. max_allocated_storage autoscaling should kick in, but this alarm exists as a backstop and cost-visibility signal."
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Sustained high RDS CPU — candidate for read replicas or an instance class upgrade."
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = local.common_tags
}

############################################
# Redis alarm
############################################
resource "aws_cloudwatch_metric_alarm" "redis_cpu_high" {
  alarm_name          = "${local.name_prefix}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Sustained high Redis CPU — check for hot keys or undersized node type."
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    ReplicationGroupId = var.redis_replication_group_id
  }

  tags = local.common_tags
}
