variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ec2_role_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "ssm_parameter_arn" {
  description = "List of ARNs for SSM Parameter Store parameters that the Grafana workspace should have read access to."
  type        = string
}

