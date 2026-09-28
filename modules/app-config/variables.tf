variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "parameter_name" {
  type = string
}

variable "initial_app_version" {
  type    = string
  default = "1.0.0"
}

variable "tags" {
  type    = map(string)
  default = {}
}
