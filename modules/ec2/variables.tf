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

variable "os" {
  description = "Operating system for EC2 instances."
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "amazon-linux"], var.os)
    error_message = "os must be 'ubuntu' or 'amazon-linux'."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "key_name" {
  description = "EC2 key pair name for emergency console access. Optional — SSM Session Manager (via the iam module) is the primary access path."
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "user_data" {
  description = "Base64-encoded user data script (bootstraps the Kubernetes node agent / Docker / app runtime)."
  type        = string
}

variable "root_volume_size" {
  type    = number
  default = 30
}

variable "root_volume_type" {
  type    = string
  default = "gp3"
}

variable "kms_key_id" {
  description = "KMS key for EBS root volume encryption. Leave null to use the account's default aws/ebs key."
  type        = string
  default     = null
}
