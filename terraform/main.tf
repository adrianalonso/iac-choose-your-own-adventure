
module "vpc" {
  source = "./modules/vpc"

  cidr_block          = "10.0.0.0/16"
  cidr_block_subnet_1 = "10.0.1.0/24"
  cidr_block_subnet_2 = "10.0.2.0/24"
  az_subnet_1         = "us-west-2a"
  az_subnet_2         = "us-west-2b"
  project_name        = var.project_name
  tags                = var.common_tags
}


module "lb" {
  source       = "./modules/lb"
  vpc_id       = module.vpc.vpc_id
  subnets      = [module.vpc.subnet_1_id, module.vpc.subnet_2_id]
  project_name = var.project_name
  tags         = var.common_tags
}

module "container_repository" {
  source       = "./modules/ecr"
  project_name = var.project_name
  tags         = var.common_tags
}

module "container_service" {
  source                         = "./modules/ecs"
  cloudwatch_group               = "/ecs/${var.project_name}"
  container_cpu                  = 128
  container_memory               = 512
  vpc_id                         = module.vpc.vpc_id
  subnets                        = [module.vpc.subnet_1_id, module.vpc.subnet_2_id]
  load_balancer_target_group_arn = module.lb.load_balancer_target_group_arn
  docker_image                   = "${module.container_repository.repository_url}:latest"
  project_name                   = var.project_name
  tags                           = var.common_tags

}


