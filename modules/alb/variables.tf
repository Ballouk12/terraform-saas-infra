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

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs from the vpc module — the ALB must live in public subnets to be internet-facing."
  type        = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "app_port" {
  description = "Port the target group forwards to on app instances."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP path the ALB polls to determine target health."
  type        = string
  default     = "/actuator/health"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Must be issued in the same region as the ALB."
  type        = string
  default = ""
}

variable "enable_deletion_protection" {
  description = "Prevent accidental ALB deletion via terraform destroy or console. Recommended true for prod."
  type        = bool
  default     = false
}
