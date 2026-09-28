locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "ec2"
  })

  ami_id = var.os == "ubuntu" ? data.aws_ami.ubuntu[0].id : data.aws_ami.amazon_linux[0].id
}

data "aws_ami" "ubuntu" {
  count       = var.os == "ubuntu" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amazon_linux" {
  count       = var.os == "amazon-linux" ? 1 : 0
  most_recent = true
  owners      = ["137112412989"] # Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  # IMDSv2 enforced (http_tokens = "required") — closes the SSRF-to-credential-theft
  # path that IMDSv1 allows. This is an AWS security best practice, not optional hardening.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true # detailed 1-minute CloudWatch metrics instead of the 5-minute basic tier
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = true
      kms_key_id            = var.kms_key_id
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${local.name_prefix}-app" })
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

