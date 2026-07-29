output "ui_service_url" {
  description = "URL of the UI component"
  value       = "http://${module.alb.lb_dns_name}"
}

output "catalog_security_group_id" {
  value = module.catalog_service.task_security_group_id
}

output "checkout_security_group_id" {
  value = module.checkout_service.task_security_group_id
}

output "orders_security_group_id" {
  value = module.orders_service.task_security_group_id
}

output "cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "service_discovery_namespace_arn" {
  value = aws_service_discovery_private_dns_namespace.this.arn
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.ec2.name
}

output "cloudwatch_logs_group_id" {
  value = aws_cloudwatch_log_group.ecs_tasks.id
}

output "task_role" {
  value = aws_iam_role.task_role.name
}

output "task_role_arn" {
  value = aws_iam_role.task_role.arn
}

output "task_execution_role" {
  value = aws_iam_role.task_execution_role.arn
}

output "target_group_prometheus_arn" {
  value = module.alb.target_group_arns[1]
}

output "target_group_alertmanager_arn" {
  value = module.alb.target_group_arns[2]
}

output "sns_topic_arn" {
  value = aws_sns_topic.monitoring_alerts.arn
}
