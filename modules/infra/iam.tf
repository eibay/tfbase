

resource "aws_iam_role" "ecs-task-role" {
  name = "${var.app_name}-${var.app_environment}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-ecsTaskRole",
    Environment = var.app_environment
  }
}

resource "aws_iam_policy" "dynamodb" {
  name        = "${var.app_name}-${var.app_environment}-task-policy-dynamodb"
  description = "Policy that allows access to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:UpdateTimeToLive",
          "dynamodb:PutItem",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:UpdateTable"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = aws_iam_policy.dynamodb.arn
}

# But another role is needed, the task execution role. This is due to the fact that the tasks will be executed “serverless” with the Fargate configuration.
# This means there’s no EC2 instances involved, meaning the permissions that usually go to the EC2 have to go somewhere else: the Fargate service. 
# This enables the service to e.g. pull the image from ECR, spin up or deregister tasks etc. AWS provides you with a predefined policy for this, so I just attached this to my role:
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-${var.app_environment}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-ecsTaskExecutionRole",
    Environment = var.app_environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
