variable "environment_name" {
  type    = string
  default = "retail-store-ecs"
}

variable "container_image_overrides" {
  type        = any
  default     = {}
  description = "Container image override object"
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "image_tag" {
  type = string
  default     = "0.1.1"
}