


# Specify the provider and access details
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.53.0"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
  region     = var.aws_region
}

module "cicd" {
  source          = "./modules/cicd"
  app_name        = var.app_name
  app_environment = var.app_environment
  cicd_params     = var.cicd_params
  input_params = {
    ecr_repository_url       = module.infra.output_ecr_repository_url
    ecs_cluster_name         = module.infra.output_ecs_cluster_name
    ecs_service_name         = module.infra.output_ecs_service_name
    ecs_taks_definition_name = module.infra.output_ecs_taks_definition_name
  }
}

module "infra" {
  source       = "./modules/infra"
  aws_region   = var.aws_region
  infra_params = var.infra_params
}
