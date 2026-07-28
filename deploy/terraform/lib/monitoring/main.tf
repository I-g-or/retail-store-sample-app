resource "aws_ecs_task_definition" "monitoring" {
  family                   = "${var.environment_name}-monitoring"
  requires_compatibilities = ["EC2"]
  cpu                      = "1024"
  memory                   = "2048"
  network_mode             = "awsvpc"
  execution_role_arn       = var.task_execution_role
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "prom/prometheus:latest"
      essential = true

      portMappings = [{
        containerPort = 9090
        hostPort      = 9090
        protocol      = "tcp"
        name          = "prometheus"
      }]

      mountPoints = [{
        sourceVolume  = "prometheus-config"
        containerPath = "/etc/prometheus"
        readOnly      = true
      }]

      command = ["--config.file=/etc/prometheus/prometheus.yml"]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.cloudwatch_logs_group_id
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "prometheus"
        }
      }
    },
    {
      name      = "alertmanager"
      image     = "prom/alertmanager:v0.27.0"
      essential = true

      portMappings = [{
        containerPort = 9093
        hostPort      = 9093
        protocol      = "tcp"
        name          = "alertmanager"
      }]

      mountPoints = [{
        sourceVolume  = "alertmanager-config"
        containerPath = "/etc/alertmanager"
        readOnly      = true
      }]

      command = ["--config.file=/etc/alertmanager/alertmanager.yml"]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.cloudwatch_logs_group_id
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "alertmanager"
        }
      }
    },
    {
      name      = "blackbox"
      image     = "prom/blackbox-exporter:v0.25.0"
      essential = true

      portMappings = [{
        containerPort = 9115
        hostPort      = 9115
        protocol      = "tcp"
        name          = "blackbox-exporter"
      }]

      mountPoints = [{
        sourceVolume  = "blackbox-config"
        containerPath = "/etc/blackbox_exporter"
        readOnly      = true
      }]

      command = ["--config.file=/etc/blackbox_exporter/blackbox.yml"]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.cloudwatch_logs_group_id
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "blackbox"
        }
      }
    }
  ])

  volume {
    name      = "prometheus-config"
    host_path = "/etc/prometheus"
  }

  volume {
    name      = "alertmanager-config"
    host_path = "/etc/alertmanager"
  }

  volume {
    name      = "blackbox-config"
    host_path = "/etc/blackbox"
  }

  depends_on = [
    aws_ssm_parameter.prometheus_config, 
    aws_ssm_parameter.alertmanager_config,
    aws_ssm_parameter.blackbox_config
    ]

  tags = var.tags
}

resource "aws_ecs_service" "monitoring" {
  name            = "monitoring"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.monitoring.arn
  desired_count   = 1

  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 100
  }

  network_configuration {
    security_groups  = [aws_security_group.monitoring.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_prometheus_arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  load_balancer {
    target_group_arn = var.target_group_alertmanager_arn
    container_name   = "alertmanager"
    container_port   = 9093
}

  service_connect_configuration {
    enabled   = true
    namespace = var.service_discovery_namespace_arn

    service {
      client_alias {
        dns_name = "prometheus"
        port     = 9090
      }
      discovery_name = "prometheus"
      port_name      = "prometheus"
    }
    service {
      client_alias {
        dns_name = "alertmanager"
        port     = 9093
      }
      discovery_name = "alertmanager"
      port_name      = "alertmanager"
    }
    service {
      client_alias {
        dns_name = "blackbox-exporter"
        port     = 9115
      }
      discovery_name = "blackbox-exporter"
      port_name      = "blackbox-exporter"
    }
  }

  tags = var.tags
}

resource "aws_ssm_parameter" "prometheus_config" {
  name  = "/${var.environment_name}/monitoring/prometheus.yml"
  type  = "String"

  value = templatefile(
    "${path.module}/../monitoring/prometheus.yml.tpl",
    {
      AWS_REGION       = var.aws_region
      ENVIRONMENT      = var.environment_name
      ECS_CLUSTER_NAME = var.cluster_name
    }
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
        ECS_CLUSTER_NAME = var.cluster_name
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
      ECS_CLUSTER_NAME = var.cluster_name
    }
  )

  tags = var.tags
}
