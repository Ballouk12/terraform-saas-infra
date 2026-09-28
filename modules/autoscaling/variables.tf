variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "launch_template_id" {
  type = string
}

variable "launch_template_version" {
  type = string
}

variable "private_subnet_ids" {
  description = "App instances launch into private subnets — never public."
  type        = list(string)
}

variable "target_group_arns" {
  type = list(string)
}

variable "min_size" {
  description = "Minimum instances — kept >=2 across AZs so no single instance failure causes downtime, satisfying the no-single-point-of-failure requirement."
  type        = number
  default     = 2
}

variable "max_size" {
  type    = number
  default = 10
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "cpu_target_value" {
  description = "Target average CPU utilization (%) for the target-tracking scaling policy."
  type        = number
  default     = 60
}

variable "health_check_grace_period" {
  description = "Seconds to wait before the first health check after an instance launches, giving the app/Kubernetes agent time to boot."
  type        = number
  default     = 120
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
