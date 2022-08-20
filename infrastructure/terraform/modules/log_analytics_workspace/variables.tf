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

variable "sku" {
  default = "PerGB2018"
}

variable "retention_in_days" {
  default = 30
}
