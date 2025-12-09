# ============================================
# ElastiCache Redis
# ============================================

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = module.vpc.database_subnets

  tags = module.tags.tags
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-${var.environment}-redis"
  engine              = "redis"
  node_type           = var.redis_node_type
  num_cache_nodes     = var.redis_num_cache_nodes
  parameter_group_name = var.redis_parameter_group_name
  engine_version      = var.redis_engine_version
  port                = 6379
  subnet_group_name   = aws_elasticache_subnet_group.redis.name
  security_group_ids  = [aws_security_group.redis.id]

  snapshot_retention_limit = var.redis_snapshot_retention_limit
  snapshot_window         = "05:00-09:00"
  maintenance_window      = "sun:05:00-sun:09:00"

  tags = module.tags.tags
}

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Redis access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.tags.tags, {
    Name = "${var.project_name}-${var.environment}-redis-sg"
  })
}