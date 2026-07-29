variable "environment_name" {
  type = string
}

variable "tags" {
  description = "List of tags to be associated with resources."
  default     = {}
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID used to create EKS cluster."
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "cluster_arn" {
  type        = string
  description = "ARN ECS cluster"
}

variable "cloudwatch_logs_group_id" {
  type = string
}

variable "service_discovery_namespace_arn" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "task_role" {
  type = string
}
variable "task_role_arn" {
  type = string
}

variable "task_execution_role" {
  type = string
}

variable "target_group_prometheus_arn" {
  type = string
}

variable "target_group_alertmanager_arn" {
  type = string
}