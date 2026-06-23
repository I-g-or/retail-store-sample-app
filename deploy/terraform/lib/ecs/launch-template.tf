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
echo "ECS user data script completed at $(date)" >> /var/log/ecs-init.log
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

  tags = merge(var.tags, { Name = "${var.environment_name}-ecs-launch-template" })
}

