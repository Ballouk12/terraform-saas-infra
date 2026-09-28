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

variable "db_subnet_group_name" {
  description = "From the vpc module — places RDS in the isolated database subnets."
  type        = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Ceiling for RDS storage autoscaling in GB — grows automatically as data accumulates without manual intervention or downtime."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Deploy a synchronous standby replica in a second AZ for automatic failover. Should be true for staging/prod, can be false for dev to save cost."
  type        = bool
  default     = true
}

variable "db_name" {
  type    = string
  default = "binaitech"
}

variable "db_username" {
  type    = string
  default = "binaitech_admin"
}

variable "backup_retention_period" {
  description = "Days of automated backups retained. Business requirement: Automatic Backups."
  type        = number
  default     = 1
}

variable "backup_window" {
  type    = string
  default = "03:00-04:00"
}

variable "maintenance_window" {
  type    = string
  default = "sun:04:30-sun:05:30"
}

variable "deletion_protection" {
  description = "Blocks accidental terraform destroy / console deletion. Should be true for staging/prod."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "If false, RDS takes a final snapshot on destroy. Should be false for staging/prod."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key for storage encryption. Leave null to use the account's default aws/rds key."
  type        = string
  default     = null
}
