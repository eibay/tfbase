variable "app_name" {
  type        = string
  description = "App name"
}

variable "app_environment" {
  type        = string
  description = "Environment"
}

variable "cicd_params" {
  description = "CICD parameters"
  type = object({
    repo_branch   = string
    repo_codestar = string
    repo_name     = string
    repo_owner    = string
    repo_url      = string
    source_type   = string
  })
}

variable "input_params" {
  description = "Output parameters from other modules"
  type = object({
    ecr_repository_url       = string
    ecs_cluster_name         = string
    ecs_service_name         = string
    ecs_taks_definition_name = string
  })
}

