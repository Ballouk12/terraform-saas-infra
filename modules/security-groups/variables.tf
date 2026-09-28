variable "project_name" {
  description = "Project prefix for naming."
  type        = string
}

variable "environment" {
  description = "Environment name (dev/staging/prod)."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID from the vpc module. All security groups are scoped to this VPC."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC, used to scope internal-only rules (e.g. SSH from within the VPC)."
  type        = string
}

variable "app_port" {
  description = "Port the application (Spring Boot backend behind Kubernetes) listens on. The ALB forwards traffic to nodes on this port."
  type        = number
  default     = 8080
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into app instances, e.g. a bastion host or VPN CIDR. Left empty by default — SSH is closed unless explicitly opened, favoring SSM Session Manager instead."
  type        = list(string)
  default     = []
}
