provider "aws" {
  region              = "us-east-1"
  allowed_account_ids = var.allowed_account_ids
}

terraform {
  backend "s3" {
    bucket = "7p-devops"
    key    = "terraform/prod/kepler_terraform.tfstate"
    region = "us-east-1"
  }
}

module "kepler" {
  source                 = "../modules/kepler"
  vpc_name               = var.vpc_name
  kepler_lb_name         = var.kepler_lb_name
  kepler_tg_name         = var.kepler_tg_name
  kepler_env             = var.kepler_env
  kepler_certificate_arn = var.kepler_certificate_arn
  kepler_branch          = var.kepler_branch
  cluster_name           = var.cluster_name
  app_subnet_name        = var.app_subnet_name
  load_balancer_sg       = var.load_balancer_sg
  task_count             = var.task_count
  app_public_subnet_name = var.app_public_subnet_name
  CI_COMMIT_ID = var.CI_COMMIT_ID
}
