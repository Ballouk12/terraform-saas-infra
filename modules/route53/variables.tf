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

variable "domain_name" {
  description = "Root domain, e.g. binaitech.com."
  type        = string
}

variable "create_zone" {
  description = "If true, creates a new public hosted zone. If false, looks up an existing zone by domain_name (e.g. when the zone is shared across environments and only prod should own it)."
  type        = bool
  default     = false
}

variable "record_name" {
  description = "Subdomain to point at the ALB, e.g. 'app' or 'app-staging'. Full FQDN becomes <record_name>.<domain_name>."
  type        = string
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}
