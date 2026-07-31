
resource "aws_ssm_parameter" "prometheus_config" {
  name  = "/${var.environment_name}/monitoring/prometheus.yml"
  type  = "String"

  value = base64encode(
    templatefile(
      "${path.module}/../monitoring/prometheus.yml.tpl",
      {
        AWS_REGION       = var.aws_region
        ENVIRONMENT      = var.environment_name
        ECS_CLUSTER_ARN = aws_ecs_cluster.cluster.arn
      }
    )
  )

  tags = var.tags
}

resource "aws_ssm_parameter" "alertmanager_config" {
  name  = "/${var.environment_name}/monitoring/alertmanager.yml"
  type  = "String"

  data_type = "text"

  value = base64encode(
    templatefile(
      "${path.module}/../monitoring/alertmanager.yml.tpl",
      {
        AWS_REGION       = var.aws_region
        ENVIRONMENT      = var.environment_name
        TOPIC_ARN        = aws_sns_topic.monitoring_alerts.arn
      }
    )
  )

  tags = var.tags
}

resource "aws_ssm_parameter" "blackbox_config" {
  name  = "/${var.environment_name}/monitoring/blackbox.yml"
  type  = "String"

  value = templatefile(
    "${path.module}/../monitoring/blackbox.yml.tpl",
    {
      AWS_REGION       = var.aws_region
      ENVIRONMENT      = var.environment_name
    }
  )

  tags = var.tags
}