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

variable "sns_topic_arn" {
  description = "From the sns module — all alarms notify this topic."
  type        = string
}

variable "asg_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "rds_instance_id" {
  type = string
}

variable "redis_replication_group_id" {
  type = string
}

variable "cpu_high_threshold" {
  type    = number
  default = 80
}

variable "alb_5xx_threshold" {
  description = "Count of 5xx responses in one 5-minute period that triggers an alert."
  type        = number
  default     = 10
}

variable "alb_latency_threshold_seconds" {
  type    = number
  default = 1
}

variable "rds_free_storage_threshold_bytes" {
  description = "Alert when RDS free storage drops below this many bytes (default 10 GiB)."
  type        = number
  default     = 10737418240
}

variable "log_retention_days" {
  description = "Retention for the application log group shipped from EC2 via the CloudWatch agent."
  type        = number
  default     = 30
}
