module "autoscaling" {
  source = "./modules/autoscaling"
  namespace = var.namespace

  vpc = module.networking.vpc
  sg = module.networking.sg
  db_config = module.data.db_config
}

module "networking" {
  source = "./module/networking"
  namespace = var.namespace
}

module "database" {
  source = "./module/database"
  namespace = var.namespace

  vpc = module.networking.vpc
  sg = module.networking.sg
}
