locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "autoscaling"
  })
}

resource "aws_autoscaling_group" "app" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.target_group_arns

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # ELB health checks (not just EC2 status checks) so an instance that's up
  # but failing app-level health checks still gets replaced — this is the
  # "auto healing" requirement in practice.
  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period
  default_instance_warmup   = var.instance_warmup

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  # Spread instances evenly across AZs rather than filling one AZ first.
  # Combined with 3 private subnets from the vpc module, this is what
  # actually delivers "no single point of failure" at the compute layer.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.min_healthy_percentage
      instance_warmup        = var.instance_warmup
      auto_rollback          = var.auto_rollback
      skip_matching          = false
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target-tracking scaling: AWS manages the add/remove decisions to hold
# average CPU near the target, which is simpler and more responsive than
# hand-rolled CloudWatch-alarm-triggered step scaling for a typical web tier.
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}
