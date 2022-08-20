variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "instance" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "application_insights_connection_string" {
  type = string
}

variable "application_insights_key" {
  type = string
}

variable "app_settings" {
  type    = map(string)
  default = {}
}
