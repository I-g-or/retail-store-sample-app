module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.environment_name}-ec2-sg"
  description = "Security group for ECS EC2 instances in ASG behind ALB"
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 32768
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Allow all traffic from ALB for ECS tasks"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.environment_name}-ecs-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  protect_from_scale_in = true 

  launch_template {
    id = aws_launch_template.ecs_ec2.id
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

