variable "project_name" {
  type    = string
  default = "binaitech"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zone_count" {
  type    = number
  default = 3
}

variable "domain_name" {
  description = "Root domain, e.g. binaitech.com"
  type        = string
}

variable "acm_certificate_arn" {
  description = "Pre-issued ACM certificate ARN for HTTPS (issue via ACM + DNS validation before applying)."
  type        = string
}

variable "app_ami_id" {
  description = "AMI ID for app instances (resolve via data \"aws_ami\" in a real setup, or pass explicitly)."
  type        = string
}

variable "app_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "key_name" {
  type    = string
  default = null
}

variable "db_username" {
  type    = string
  default = "binaitech_admin"
}

variable "alert_emails" {
  type = list(string)
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "initial_app_version" {
  type    = string
  default = "1.0.0"
}

variable "app_container_name" {
  type    = string
  default = "binaitech-app"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "instance_warmup" {
  type    = number
  default = 300
}

variable "min_healthy_percentage" {
  type    = number
  default = 90
}

variable "auto_rollback" {
  type    = bool
  default = true
}
