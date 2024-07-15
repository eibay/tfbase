
# Security group for the ALB that allows only access via TCP ports 80 and 443 (aka HTTP and HTTPS)
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-${var.app_environment}-sg-alb"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Security Group needed for ECS task, that will later house containers, allowing ingress access only to the port that is exposted by the task
resource "aws_security_group" "ecs-tasks" {
  name   = "${var.app_name}-${var.app_environment}-sg-ecs-task"
  vpc_id = aws_vpc.main_vpc.id

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "alb-to-ecs" {
  type                     = "ingress"
  from_port                = var.infra_params.app_port
  to_port                  = var.infra_params.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs-tasks.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "ecs-to-alb" {
  type                     = "egress"
  from_port                = var.infra_params.app_port
  to_port                  = var.infra_params.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.ecs-tasks.id

}
