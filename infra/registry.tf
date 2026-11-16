# Data sources that read the three ECR repositories
# created by the bootstrap, only read here
data "aws_ecr_repository" "service" {
  for_each = toset(["vote", "result", "worker"])

  name = "${var.name_prefix}-${each.key}"
}
