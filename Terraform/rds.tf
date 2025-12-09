# ============================================
# RDS PostgreSQL Database
# ============================================

# Random password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = false
}

# RDS PostgreSQL instance
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.project_name}-${var.environment}-postgresql"

  engine               = "postgres"
  engine_version       = var.database_engine_version
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = var.database_instance_class

  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_max_allocated_storage
  storage_encrypted     = true
  storage_type          = "gp3"

  db_name  = var.database_name
  username = var.database_username
  password = random_password.rds_password.result
  port     = 5432

  multi_az               = var.database_multi_az
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  maintenance_window = var.rds_maintenance_window
  backup_window      = var.rds_backup_window
  backup_retention_period = var.enable_rds_automated_backups ? var.database_backup_retention_period : 0

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  deletion_protection = var.database_deletion_protection
  skip_final_snapshot = var.environment == "production" ? false : true
  final_snapshot_identifier_prefix = "${var.project_name}-${var.environment}-final-snapshot"

  parameters = [
    {
      name  = "rds.force_ssl"
      value = "1"
    },
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "track_activity_query_size"
      value = "2048"
    },
    {
      name  = "log_statement"
      value = "ddl"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]

  tags = module.tags.tags
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "PostgreSQL access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.tags.tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })
}