resource "aws_s3_bucket" "codepipeline-bucket" {
  bucket = "${var.app_name}-${var.app_environment}-codepipeline-bucket"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.app_name}-${var.app_environment}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.app_name}-codepipeline-role",
    Environment = var.app_environment
  }
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

resource "aws_iam_role_policy_attachment" "pipeline_container_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_policy" "pipeline_extra_policy" {
  name        = "${var.app_name}-${var.app_environment}-pipeline_extra_policy"
  description = "Policy for CodePipeline extra required permissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = [
          "${aws_s3_bucket.codepipeline-bucket.arn}",
          "${aws_s3_bucket.codepipeline-bucket.arn}/*",
          "*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = "${var.cicd_params.repo_codestar}"
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ],
        Resource = "*"
      },
    ]
  })

  tags = {
    Name        = "${var.app_name}-pipeline_extra_policy",
    Environment = var.app_environment
  }
}

resource "aws_iam_role_policy_attachment" "pipeline_extra_policy_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.pipeline_extra_policy.arn
}


resource "aws_codepipeline" "java-ecs-pipeline" {
  name     = "${var.app_name}-${var.app_environment}-java-ecs-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline-bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = var.cicd_params.repo_codestar
        FullRepositoryId = "${var.cicd_params.repo_owner}/${var.cicd_params.repo_name}"
        BranchName       = var.cicd_params.repo_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build-Image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.push-app-image.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy-To-ECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ClusterName = var.input_params.ecs_cluster_name
        ServiceName = var.input_params.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Name        = "${var.app_name}-java-ecs-pipeline",
    Environment = var.app_environment
  }

}

