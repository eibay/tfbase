

# On this file has all necessary resources to pull latest push form Git repository
# Deploy a docker image and push to a ECR repository
# The necessary resources are defined all in this file to avoid confusion with the rest of the architecture
# Create IAM role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.app_name}-${var.app_environment}-codebuild_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-codebuild-role",
    Environment = var.app_environment
  }
}

# Attach policies to the IAM role
resource "aws_iam_role_policy_attachment" "container_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Policy to allow creation of log streams
resource "aws_iam_role_policy_attachment" "codebuild_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_policy" "build_extra_policy" {
  name        = "${var.app_name}-${var.app_environment}-build_extra_policy"
  description = "Policy for CodePipeline extra required permissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "s3:CreateBucket",
          "s3:GetObject",
          "s3:List*",
          "s3:PutObject"

        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-build_extra_policy",
    Environment = var.app_environment
  }
}

resource "aws_iam_role_policy_attachment" "build_extra_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.build_extra_policy.arn
}

# Codebuild project, it will push Application code docker image to ECR
resource "aws_codebuild_project" "push-app-image" {
  name          = "${var.app_name}-${var.app_environment}-push-app-image"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 5

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPO"
      value = var.input_params.ecr_repository_url
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "ECR_IMAGE_TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.app_name}-${var.app_environment}-log-group"
      stream_name = "${var.app_name}-${var.app_environment}-log-stream"
    }

    s3_logs {
      status = "DISABLED"
      # location = "${aws_s3_bucket.codebuild-logs.id}/build-log"
    }
  }

  source {
    type            = var.cicd_params.source_type
    location        = var.cicd_params.repo_url
    git_clone_depth = 1
    buildspec       = <<EOF
    version: 0.2

    phases:
      pre_build:
        commands:
          - echo Logging in to Amazon ECR...
          - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPO
      build:
        commands:
          - echo Build started on `date`
          - echo Building the Docker image...
          - docker build -t $ECR_REPO:$ECR_IMAGE_TAG .
          - docker tag $ECR_REPO:$ECR_IMAGE_TAG $ECR_REPO:$CODEBUILD_RESOLVED_SOURCE_VERSION
      post_build:
        commands:
          - echo Build completed on `date`
          - echo Pushing the Docker image...
          - docker push $ECR_REPO:$ECR_IMAGE_TAG
          - docker push $ECR_REPO:$CODEBUILD_RESOLVED_SOURCE_VERSION
          - echo Creating imagedefinitions.json file...
          - printf '[{"name":"${var.input_params.ecs_taks_definition_name}","imageUri":"%s"}]' $ECR_REPO:$CODEBUILD_RESOLVED_SOURCE_VERSION > imagedefinitions.json
    artifacts:
      files: imagedefinitions.json
    EOF
  }

  source_version = "main"

  tags = {
    Name        = "${var.app_name}-push-app-image",
    Environment = var.app_environment
  }

}
