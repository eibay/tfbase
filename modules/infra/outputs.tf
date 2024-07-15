

output "output_alb_dns_name" {
  value       = aws_alb.alb.dns_name
  description = "ALB DNS Name"
}

output "output_ecr_repository_url" {
  value       = aws_ecr_repository.aws_ecr.repository_url
  description = "ECR Repository URL"
}

output "output_ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "Cluster Name"
}

output "output_ecs_service_name" {
  value       = aws_ecs_service.ecs-service.name
  description = "ECS Service Name"
}

output "output_ecs_taks_definition_name" {
  value       = "${var.app_name}-${var.app_environment}-java-ecs-demo"
  description = "ECS Task Definition name"
}
