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

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs the app tier needs access to (media uploads, etc). Used to build a least-privilege scoped policy instead of a wildcard s3:* on Resource = \"*\"."
  type        = list(string)
  default     = []
}

variable "enable_ssm" {
  description = "Attach AmazonSSMManagedInstanceCore so instances are reachable via SSM Session Manager instead of requiring open SSH security group rules."
  type        = bool
  default     = true
}

variable "enable_cloudwatch_agent" {
  description = "Attach CloudWatchAgentServerPolicy so instances can ship custom metrics/logs."
  type        = bool
  default     = true
}

variable "ecr_repository_arn" {
  description = "ECR repository ARN from which the application image is pulled."
  type        = string
}

variable "app_version_parameter_arn" {
  description = "SSM parameter ARN containing the application image tag."
  type        = string
}
