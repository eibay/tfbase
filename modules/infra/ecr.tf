# Create ECR Container Registry with the code bellow:
resource "aws_ecr_repository" "aws_ecr" {
  name = "${var.app_name}-${var.app_environment}-ecr"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.app_name}-ecr",
    Environment = var.app_environment
  }
}

resource "aws_ecr_lifecycle_policy" "ecr-policy" {
  repository = aws_ecr_repository.aws_ecr.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })

}
