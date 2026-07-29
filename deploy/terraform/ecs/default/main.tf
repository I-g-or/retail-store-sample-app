module "tags" {
  source = "../../lib/tags"

  environment_name = var.environment_name
}

module "vpc" {
  source = "../../lib/vpc"

  environment_name = var.environment_name

  tags = module.tags.result
}

module "dependencies" {
  source = "../../lib/dependencies"

  environment_name = var.environment_name
  tags             = module.tags.result

  vpc_id             = module.vpc.inner.vpc_id
  subnet_ids         = module.vpc.inner.private_subnets
  availability_zones = module.vpc.inner.azs

  catalog_security_group_id  = module.retail_app_ecs.catalog_security_group_id
  orders_security_group_id   = module.retail_app_ecs.orders_security_group_id
  checkout_security_group_id = module.retail_app_ecs.checkout_security_group_id
}

locals {
  container_image_overrides = {
    default_repository = "${var.aws_account_id}.dkr.ecr.il-central-1.amazonaws.com"
    default_tag        = var.image_tag

    ui       = "${var.aws_account_id}.dkr.ecr.il-central-1.amazonaws.com/retail-store-sample-ui:${var.image_tag}"
    catalog  = "${var.aws_account_id}.dkr.ecr.il-central-1.amazonaws.com/retail-store-sample-catalog:${var.image_tag}"
    cart     = "${var.aws_account_id}.dkr.ecr.il-central-1.amazonaws.com/retail-store-sample-cart:${var.image_tag}"
    checkout = "${var.aws_account_id}.dkr.ecr.il-central-1.amazonaws.com/retail-store-sample-checkout:${var.image_tag}"
    orders   = "${var.aws_account_id}.dkr.ecr.il-central-1.amazonaws.com/retail-store-sample-orders:${var.image_tag}"
    assets   = "${var.aws_account_id}.dkr.ecr.il-central-1.amazonaws.com/retail-store-sample-assets:${var.image_tag}"
  }
}

module "retail_app_ecs" {
  source = "../../lib/ecs"

  environment_name          = var.environment_name
  vpc_id                    = module.vpc.inner.vpc_id
  vpc_cidr                  = module.vpc.inner.vpc_cidr_block
  subnet_ids                = module.vpc.inner.private_subnets
  public_subnet_ids         = module.vpc.inner.public_subnets
  tags                      = module.tags.result
  container_image_overrides = local.container_image_overrides
  aws_region                = var.aws_region

  catalog_db_endpoint = module.dependencies.catalog_db_endpoint
  catalog_db_port     = module.dependencies.catalog_db_port
  catalog_db_name     = module.dependencies.catalog_db_database_name
  catalog_db_username = module.dependencies.catalog_db_master_username
  catalog_db_password = module.dependencies.catalog_db_master_password

  carts_dynamodb_table_name = module.dependencies.carts_dynamodb_table_name
  carts_dynamodb_policy_arn = module.dependencies.carts_dynamodb_policy_arn

  checkout_redis_endpoint = module.dependencies.checkout_elasticache_primary_endpoint
  checkout_redis_port     = module.dependencies.checkout_elasticache_port

  orders_db_endpoint = module.dependencies.orders_db_endpoint
  orders_db_port     = module.dependencies.orders_db_port
  orders_db_name     = module.dependencies.orders_db_database_name
  orders_db_username = module.dependencies.orders_db_master_username
  orders_db_password = module.dependencies.orders_db_master_password

  mq_endpoint = module.dependencies.mq_broker_endpoint
  mq_username = module.dependencies.mq_user
  mq_password = module.dependencies.mq_password
}

module "monitoring" {
  source = "../../lib/monitoring"

  environment_name                = var.environment_name
  aws_region                      = var.aws_region
  cluster_arn                     = module.retail_app_ecs.cluster_arn
  task_role                       = module.retail_app_ecs.task_role
  task_role_arn                   = module.retail_app_ecs.task_role_arn
  task_execution_role             = module.retail_app_ecs.task_execution_role
  vpc_id                          = module.vpc.inner.vpc_id
  vpc_cidr                        = module.vpc.inner.vpc_cidr_block
  subnet_ids                      = module.vpc.inner.private_subnets
  target_group_prometheus_arn     = module.retail_app_ecs.target_group_prometheus_arn
  target_group_alertmanager_arn   = module.retail_app_ecs.target_group_alertmanager_arn
  tags                            = module.tags.result
  service_discovery_namespace_arn = module.retail_app_ecs.service_discovery_namespace_arn
  capacity_provider_name          = module.retail_app_ecs.capacity_provider_name
  cloudwatch_logs_group_id        = module.retail_app_ecs.cloudwatch_logs_group_id
  alertmanager_sns_arn            = module.retail_app_ecs.alertmanager_sns_arn

  depends_on = [module.retail_app_ecs]

}
