# ============================================
# AWS Secrets Manager Secrets
# ============================================

# AWS Secrets Manager secrets
resource "aws_secretsmanager_secret" "database" {
  name        = "/${var.project_name}/${var.environment}/database/credentials"
  description = "Database credentials for ${var.project_name} in ${var.environment} environment"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    host     = module.rds.db_instance_address
    port     = module.rds.db_instance_port
    username = var.database_username
    password = random_password.rds_password.result
    database = var.database_name
    sslmode  = "require"
  })
}

resource "aws_secretsmanager_secret" "redis" {
  name        = "/${var.project_name}/${var.environment}/redis/credentials"
  description = "Redis credentials for ${var.project_name} in ${var.environment} environment"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host     = aws_elasticache_cluster.redis.cache_nodes[0].address
    port     = aws_elasticache_cluster.redis.port
  })
}

resource "aws_secretsmanager_secret" "s3" {
  name        = "/${var.project_name}/${var.environment}/s3/credentials"
  description = "S3 bucket information for ${var.project_name} in ${var.environment} environment"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "s3" {
  secret_id = aws_secretsmanager_secret.s3.id
  secret_string = jsonencode({
    bucket  = aws_s3_bucket.images.bucket
    region  = var.aws_region
  })
}

# Service secrets
resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "random_password" "api_key" {
  length  = 32
  special = false
}

resource "random_password" "image_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "services" {
  name        = "/${var.project_name}/${var.environment}/services/keys"
  description = "Service API keys and secrets for ${var.project_name} in ${var.environment} environment"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "services" {
  secret_id = aws_secretsmanager_secret.services.id
  secret_string = jsonencode({
    jwt_secret_key     = random_password.jwt_secret.result
    api_rate_limit_key = random_password.api_key.result
    image_service_key  = random_password.image_key.result
  })
}