resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.app_environment}-cluster"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.app_name}-ecs",
    Environment = var.app_environment
  }
}

resource "aws_ecs_task_definition" "main-task" {
  family                   = "${var.app_name}_ECS_TaskDefinition_${var.app_environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs-task-role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-${var.app_environment}-java-ecs-demo",
      image     = "${aws_ecr_repository.aws_ecr.repository_url}:latest",
      essential = true,

      portMappings = [
        {
          protocol      = "tcp"
          containerPort = var.infra_params.app_port #8080
          hostPort      = var.infra_params.app_port
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${aws_cloudwatch_log_group.log-group.id}",
          awslogs-region        = "${var.aws_region}",
          awslogs-stream-prefix = "${var.app_name}-${var.app_environment}"
        }
      }
    }
  ])

}

resource "aws_ecs_service" "ecs-service" {
  name                               = "${var.app_name}-${var.app_environment}-ecs-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main-task.arn
  desired_count                      = 1 # 2 is minimum ideal, putting one just for dev test
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
    security_groups = [
      aws_security_group.ecs-tasks.id
    ]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.alb-tg.arn
    container_name   = "${var.app_name}-${var.app_environment}-java-ecs-demo"
    container_port   = var.infra_params.app_port #8080
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
