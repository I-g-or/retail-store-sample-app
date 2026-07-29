data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_launch_template" "ecs_ec2" {
  name_prefix = "${var.environment_name}-ecs-ec2-"

  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.ec2_instance_type     # "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2-profile.name
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
echo "ECS_LOGLEVEL=info" >> /etc/ecs/ecs.config

sudo mkdir -p /etc/prometheus
sudo mkdir -p /etc/alertmanager
sudo mkdir -p /etc/blackbox

sudo aws ssm get-parameter \
    --name "/dev/monitoring/prometheus.yml" \
    --with-decryption \
    --query Parameter.Value \
    --output text \
    | sudo tee /etc/prometheus/prometheus.yml

sudo chmod 644 /etc/prometheus/*.yml
sudo chown root:root /etc/prometheus/*.yml

sudo aws ssm get-parameter \
    --name "/dev/monitoring/alertmanager.yml" \
    --with-decryption \
    --query Parameter.Value \
    --output text \
    | sudo tee /etc/alertmanager/alertmanager.yml

sudo chmod 644 /etc/alertmanager/*.yml
sudo chown root:root /etc/alertmanager/*.yml

sudo aws ssm get-parameter \
  --name "/dev/monitoring/blackbox.yml" \
  --with-decryption \
  --query Parameter.Value \
  --output text \
  | sudo tee /etc/blackbox/blackbox.yml

sudo chmod 644 /etc/blackbox/*.yml
sudo chown root:root /etc/blackbox/*.yml
EOF
)

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [module.ec2_sg.security_group_id]
    subnet_id                   = null
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  depends_on = [
    aws_ssm_parameter.prometheus_config, 
    aws_ssm_parameter.alertmanager_config,
    aws_ssm_parameter.blackbox_config
    ]

  tags = merge(var.tags, { Name = "${var.environment_name}-ecs-launch-template" })
}

