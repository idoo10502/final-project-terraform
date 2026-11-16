# ECS cluster, environment variables and secrets of the services, the three calls to the service module
resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"
}

locals {
  redis_host = aws_elasticache_cluster.redis.cache_nodes[0].address

  db_env = {
    DB_HOST = aws_db_instance.db.address
    DB_PORT = tostring(aws_db_instance.db.port)
    DB_USER = aws_db_instance.db.username
    DB_NAME = aws_db_instance.db.db_name
    DB_SSL  = "true"
  }

  db_secrets = {
    DB_PASSWORD = aws_secretsmanager_secret.db.arn
  }

  # what every service shares
  service_common = {
    cluster_id         = aws_ecs_cluster.main.id
    execution_role_arn = aws_iam_role.exec.arn
    subnet_ids         = [for s in aws_subnet.public : s.id]
    security_group_ids = [aws_security_group.ecs.id]
  }
}

module "vote" {
  source = "./modules/service"

  name               = "${local.name}-vote"
  image              = "${data.aws_ecr_repository.service["vote"].repository_url}:${var.image_tag}"
  desired_count      = var.desired_count
  cluster_id         = local.service_common.cluster_id
  execution_role_arn = local.service_common.execution_role_arn
  subnet_ids         = local.service_common.subnet_ids
  security_group_ids = local.service_common.security_group_ids

  environment = {
    REDIS_HOST = local.redis_host
    OPTION_A   = var.option_a
    OPTION_B   = var.option_b
  }

  container_port   = 80
  target_group_arn = aws_lb_target_group.app["vote"].arn

  depends_on = [aws_lb_listener.app, aws_iam_role_policy_attachment.exec]
}

module "result" {
  source = "./modules/service"

  name               = "${local.name}-result"
  image              = "${data.aws_ecr_repository.service["result"].repository_url}:${var.image_tag}"
  desired_count      = var.desired_count
  cluster_id         = local.service_common.cluster_id
  execution_role_arn = local.service_common.execution_role_arn
  subnet_ids         = local.service_common.subnet_ids
  security_group_ids = local.service_common.security_group_ids

  environment = local.db_env
  secrets     = local.db_secrets

  container_port   = 80
  target_group_arn = aws_lb_target_group.app["result"].arn

  depends_on = [aws_lb_listener.app, aws_iam_role_policy_attachment.exec, aws_iam_role_policy.read_db_secret]
}

module "worker" {
  source = "./modules/service"

  name               = "${local.name}-worker"
  image              = "${data.aws_ecr_repository.service["worker"].repository_url}:${var.image_tag}"
  desired_count      = var.desired_count
  cluster_id         = local.service_common.cluster_id
  execution_role_arn = local.service_common.execution_role_arn
  subnet_ids         = local.service_common.subnet_ids
  security_group_ids = local.service_common.security_group_ids

  environment = merge(local.db_env, { REDIS_HOST = local.redis_host })
  secrets     = local.db_secrets

  # no container_port, no target_group_arn: worker is not behind the ALB (L3)

  depends_on = [aws_iam_role_policy_attachment.exec, aws_iam_role_policy.read_db_secret]
}
