# Prometheus
resource "aws_iam_policy" "prometheus_ecs_discovery" {
  name        = "${var.environment_name}-prometheus-ecs-discovery"
  description = "Permissions for Prometheus to discover ECS services and collect metrics"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListClusters",
          "ecs:ListTasks",
          "ecs:ListServices",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeServices",
          "ecs:DescribeClusters",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_prometheus" {
  role       = var.task_role
  policy_arn = aws_iam_policy.prometheus_ecs_discovery.arn
}


# Alertmanager
resource "aws_iam_policy" "alertmanager_sns" {
  name        = "${var.environment_name}-alertmanager-sns"
  description = "Permissions for Alertmanager to publish to SNS"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.monitoring_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_alertmanager" {
  role       = var.task_role
  policy_arn = var.alertmanager_sns_arn
}