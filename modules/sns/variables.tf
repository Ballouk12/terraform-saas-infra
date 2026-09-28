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

variable "alert_emails" {
  description = "List of email addresses to subscribe to infrastructure alerts. Each address gets a confirmation email that must be accepted before alerts flow."
  type        = list(string)
}
