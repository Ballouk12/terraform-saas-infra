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

variable "subnet_group_name" {
  description = "From the vpc module — places Redis in the isolated database subnets."
  type        = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "engine_version" {
  type    = string
  default = "7.1"
}

variable "num_cache_clusters" {
  description = "Number of nodes (1 primary + N-1 replicas). >=2 enables automatic_failover for HA — no single point of failure on the cache tier used for sessions/rate limiting."
  type        = number
  default     = 2
}

variable "automatic_failover_enabled" {
  type    = bool
  default = true
}

variable "at_rest_encryption_enabled" {
  type    = bool
  default = true
}

variable "transit_encryption_enabled" {
  type    = bool
  default = true
}

variable "snapshot_retention_limit" {
  description = "Days of automatic daily snapshots retained."
  type        = number
  default     = 5
}
