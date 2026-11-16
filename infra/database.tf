# RDS: subnet group and instance, the generated password and its Secrets Manager secret
resource "random_password" "db" {
  length  = 24
  special = false # ';' and '=' break the .NET connection string
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name}-db-password"
  recovery_window_in_days = 0 # deleted at once on destroy
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}

resource "aws_db_subnet_group" "db" {
  name       = "${local.name}-db"
  subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_db_instance" "db" {
  identifier             = "${local.name}-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "votes"
  username               = "voteadmin"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}
