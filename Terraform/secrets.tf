# ============================================
# AWS Secrets Manager - Database Secrets
# ============================================

# Database credentials secret (using module.rds outputs)
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
    endpoint = module.rds.db_instance_endpoint
    engine   = "postgresql"
  })

  depends_on = [module.rds]
}

# Separate secret for each service database connection
resource "aws_secretsmanager_secret" "api_service_database" {
  name        = "/${var.project_name}/${var.environment}/api-service/database"
  description = "Database configuration for API Service"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "api_service_database" {
  secret_id = aws_secretsmanager_secret.api_service_database.id
  secret_string = jsonencode({
    url      = "postgresql://${var.database_username}:${random_password.rds_password.result}@${module.rds.db_instance_endpoint}/${var.database_name}?sslmode=require"
    host     = module.rds.db_instance_address
    port     = module.rds.db_instance_port
    database = var.database_name
  })

  depends_on = [module.rds]
}

resource "aws_secretsmanager_secret" "auth_service_database" {
  name        = "/${var.project_name}/${var.environment}/auth-service/database"
  description = "Database configuration for Auth Service"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "auth_service_database" {
  secret_id = aws_secretsmanager_secret.auth_service_database.id
  secret_string = jsonencode({
    url      = "postgresql://${var.database_username}:${random_password.rds_password.result}@${module.rds.db_instance_endpoint}/${var.database_name}?sslmode=require"
    host     = module.rds.db_instance_address
    port     = module.rds.db_instance_port
    database = var.database_name
    pool_size = 10
  })

  depends_on = [module.rds]
}

# ============================================
# Redis Secrets (ElastiCache)
# ============================================

# Main Redis secret
resource "aws_secretsmanager_secret" "redis" {
  name        = "/${var.project_name}/${var.environment}/redis/credentials"
  description = "Redis credentials for ${var.project_name} in ${var.environment} environment"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host      = aws_elasticache_cluster.redis.cache_nodes[0].address
    port      = aws_elasticache_cluster.redis.port
    endpoint  = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
    ssl       = false
    password  = ""  # Redis without password (or use auth token if enabled)
  })

  depends_on = [aws_elasticache_cluster.redis]
}

# Service-specific Redis secrets
resource "aws_secretsmanager_secret" "api_service_redis" {
  name        = "/${var.project_name}/${var.environment}/api-service/redis"
  description = "Redis configuration for API Service"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "api_service_redis" {
  secret_id = aws_secretsmanager_secret.api_service_redis.id
  secret_string = jsonencode({
    url       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
    host      = aws_elasticache_cluster.redis.cache_nodes[0].address
    port      = aws_elasticache_cluster.redis.port
    db        = 0
    cache_ttl = 300
  })

  depends_on = [aws_elasticache_cluster.redis]
}

resource "aws_secretsmanager_secret" "auth_service_redis" {
  name        = "/${var.project_name}/${var.environment}/auth-service/redis"
  description = "Redis configuration for Auth Service"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "auth_service_redis" {
  secret_id = aws_secretsmanager_secret.auth_service_redis.id
  secret_string = jsonencode({
    url          = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
    host         = aws_elasticache_cluster.redis.cache_nodes[0].address
    port         = aws_elasticache_cluster.redis.port
    session_ttl  = 86400  # 24 hours
    token_ttl    = 3600   # 1 hour
  })

  depends_on = [aws_elasticache_cluster.redis]
}

# ============================================
# S3 Secrets
# ============================================

resource "aws_secretsmanager_secret" "image_service_s3" {
  name        = "/${var.project_name}/${var.environment}/image-service/s3"
  description = "S3 configuration for Image Service"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "image_service_s3" {
  secret_id = aws_secretsmanager_secret.image_service_s3.id
  secret_string = jsonencode({
    bucket          = aws_s3_bucket.images.bucket
    region          = var.aws_region
    bucket_arn      = aws_s3_bucket.images.arn
    max_file_size   = 10485760  # 10MB
    allowed_formats = "jpg,jpeg,png,gif,webp"
  })

  depends_on = [aws_s3_bucket.images]
}

# ============================================
# JWT and API Keys
# ============================================

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "random_password" "api_key" {
  length  = 32
  special = false
}

resource "random_password" "image_service_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "jwt_secrets" {
  name        = "/${var.project_name}/${var.environment}/jwt/credentials"
  description = "JWT secrets for ${var.project_name}"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "jwt_secrets" {
  secret_id = aws_secretsmanager_secret.jwt_secrets.id
  secret_string = jsonencode({
    secret_key    = random_password.jwt_secret.result
    issuer        = var.project_name
    audience      = var.project_name
    access_token_expiry  = 3600    # 1 hour
    refresh_token_expiry = 2592000 # 30 days
  })
}

resource "aws_secretsmanager_secret" "api_keys" {
  name        = "/${var.project_name}/${var.environment}/api/keys"
  description = "API keys for ${var.project_name} services"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    api_service_key    = random_password.api_key.result
    image_service_key  = random_password.image_service_key.result
    rate_limit_per_minute = 100
    rate_limit_per_hour   = 1000
  })
}

# ============================================
# Service-specific Secrets
# ============================================

resource "aws_secretsmanager_secret" "api_service_secrets" {
  name        = "/${var.project_name}/${var.environment}/api-service/secrets"
  description = "All secrets for API Service"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "api_service_secrets" {
  secret_id = aws_secretsmanager_secret.api_service_secrets.id
  secret_string = jsonencode({
    database = {
      url      = "postgresql://${var.database_username}:${random_password.rds_password.result}@${module.rds.db_instance_endpoint}/${var.database_name}?sslmode=require"
    }
    redis = {
      url      = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
    }
    jwt = {
      secret_key = random_password.jwt_secret.result
    }
    services = {
      auth_url  = "http://auth-service.auth.svc.cluster.local:8080"
      image_url = "http://image-service.image.svc.cluster.local:8080"
    }
  })

  depends_on = [module.rds, aws_elasticache_cluster.redis]
}

resource "aws_secretsmanager_secret" "auth_service_secrets" {
  name        = "/${var.project_name}/${var.environment}/auth-service/secrets"
  description = "All secrets for Auth Service"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "auth_service_secrets" {
  secret_id = aws_secretsmanager_secret.auth_service_secrets.id
  secret_string = jsonencode({
    database = {
      url      = "postgresql://${var.database_username}:${random_password.rds_password.result}@${module.rds.db_instance_endpoint}/${var.database_name}?sslmode=require"
    }
    redis = {
      url      = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
    }
    jwt = {
      secret_key = random_password.jwt_secret.result
    }
    security = {
      password_hash_cost = 12
      token_length      = 32
    }
  })

  depends_on = [module.rds, aws_elasticache_cluster.redis]
}

resource "aws_secretsmanager_secret" "image_service_secrets" {
  name        = "/${var.project_name}/${var.environment}/image-service/secrets"
  description = "All secrets for Image Service"

  recovery_window_in_days = var.secrets_recovery_window_days

  tags = module.tags.tags
}

resource "aws_secretsmanager_secret_version" "image_service_secrets" {
  secret_id = aws_secretsmanager_secret.image_service_secrets.id
  secret_string = jsonencode({
    s3 = {
      bucket          = aws_s3_bucket.images.bucket
      region          = var.aws_region
    }
    processing = {
      max_width        = 1920
      max_height       = 1080
      quality          = 85
      thumbnail_width  = 300
      thumbnail_height = 300
    }
    api_key = random_password.image_service_key.result
  })

  depends_on = [aws_s3_bucket.images]
}