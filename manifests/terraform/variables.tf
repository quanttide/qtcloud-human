variable "region" {
  description = "阿里云地域"
  type        = string
  default     = "cn-hangzhou"
}

variable "project" {
  description = "项目名（资源命名前缀）"
  type        = string
  default     = "qtcloud-human"
}

variable "environment" {
  description = "环境：dev / prod"
  type        = string
  default     = "prod"
}
