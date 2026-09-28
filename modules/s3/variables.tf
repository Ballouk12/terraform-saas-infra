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

variable "bucket_purpose" {
  description = "Short suffix identifying what the bucket is for, e.g. 'media', 'backups'. Produces names like binaitech-prod-media."
  type        = string
}

variable "enable_versioning" {
  description = "Object versioning — required by the business 'Versioning' DR requirement, and it's what lets you recover from accidental overwrite/delete."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key for SSE-KMS bucket encryption. Leave null to use the account's default aws/s3 key."
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep old (noncurrent) object versions before permanent deletion — controls storage cost growth from versioning."
  type        = number
  default     = 90
}

variable "transition_to_ia_days" {
  description = "Days before current objects move to Standard-IA (cheaper, for infrequently accessed media/reports)."
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Days before current objects move to Glacier Instant Retrieval (long-term archival, e.g. old daily reports)."
  type        = number
  default     = 180
}
