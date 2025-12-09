# ============================================
# AWS Configuration Variables
# ============================================

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d+$", var.aws_region))
    error_message = "AWS region must be in format like us-east-1, eu-west-1, etc."
  }
}

variable "aws_access_key" {
  description = "AWS Access Key for programmatic access"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key for programmatic access"
  type        = string
  default     = ""
  sensitive   = true
}

# ============================================
# Project Configuration Variables
# ============================================

variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  default     = "sre-project"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name (e.g., staging, production, development)"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production", "development"], var.environment)
    error_message = "Environment must be either 'staging', 'production', or 'development'."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {
    ManagedBy   = "Terraform"
    Department  = "Engineering"
    CostCenter  = "12345"
  }
}

# ============================================
# VPC & Network Configuration Variables
# ============================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3
    error_message = "Number of availability zones must be between 2 and 3."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "Number of public subnet CIDRs must match number of availability zones."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "Number of private subnet CIDRs must match number of availability zones."
  }
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]

  validation {
    condition     = length(var.database_subnet_cidrs) == length(var.availability_zones)
    error_message = "Number of database subnet CIDRs must match number of availability zones."
  }
}

# ============================================
# EKS Cluster Configuration Variables
# ============================================

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[0-8]|29)$", var.eks_cluster_version))
    error_message = "EKS cluster version must be between 1.20 and 1.29."
  }
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^[a-z][0-9]?\\.[a-z]+[0-9]*$", var.eks_node_instance_type))
    error_message = "Instance type must be valid AWS EC2 instance type."
  }
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes in the node group"
  type        = number
  default     = 2

  validation {
    condition     = var.eks_node_min_size >= 1 && var.eks_node_min_size <= 10
    error_message = "Minimum node size must be between 1 and 10."
  }
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes in the node group"
  type        = number
  default     = 5

  validation {
    condition     = var.eks_node_max_size >= var.eks_node_min_size && var.eks_node_max_size <= 20
    error_message = "Maximum node size must be between minimum size and 20."
  }
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes in the node group"
  type        = number
  default     = 2

  validation {
    condition     = var.eks_node_desired_size >= var.eks_node_min_size && var.eks_node_desired_size <= var.eks_node_max_size
    error_message = "Desired node size must be between minimum and maximum size."
  }
}

variable "eks_node_disk_size" {
  description = "Disk size in GB for EKS worker nodes"
  type        = number
  default     = 50

  validation {
    condition     = var.eks_node_disk_size >= 20 && var.eks_node_disk_size <= 100
    error_message = "Disk size must be between 20GB and 100GB."
  }
}

variable "eks_node_disk_type" {
  description = "Disk type for EKS worker nodes"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.eks_node_disk_type)
    error_message = "Disk type must be one of: gp2, gp3, io1, io2."
  }
}

# ============================================
# RDS Database Configuration Variables
# ============================================

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "sredb"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.database_name))
    error_message = "Database name must be lowercase alphanumeric with underscores, starting with a letter."
  }
}

variable "database_username" {
  description = "Master username for PostgreSQL database"
  type        = string
  default     = "sreadmin"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.database_username))
    error_message = "Database username must be lowercase alphanumeric with underscores, starting with a letter."
  }
}

variable "database_instance_class" {
  description = "RDS instance class for PostgreSQL"
  type        = string
  default     = "db.t3.micro"

  validation {
    condition     = can(regex("^db\\.[a-z][0-9]?\\.[a-z]+$", var.database_instance_class))
    error_message = "Database instance class must be a valid RDS instance class."
  }
}

variable "database_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.database_allocated_storage >= 20 && var.database_allocated_storage <= 65536
    error_message = "Allocated storage must be between 20GB and 65536GB."
  }
}

variable "database_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.database_max_allocated_storage >= var.database_allocated_storage
    error_message = "Maximum allocated storage must be greater than or equal to allocated storage."
  }
}

variable "database_backup_retention_period" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7

  validation {
    condition     = var.database_backup_retention_period >= 0 && var.database_backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "database_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "database_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = true
}

variable "database_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.3"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.database_engine_version))
    error_message = "Database engine version must be in format X.Y."
  }
}

# ============================================
# ElastiCache Redis Configuration Variables
# ============================================

variable "redis_node_type" {
  description = "Node type for ElastiCache Redis"
  type        = string
  default     = "cache.t3.micro"

  validation {
    condition     = can(regex("^cache\\.[a-z][0-9]?\\.[a-z]+$", var.redis_node_type))
    error_message = "Redis node type must be a valid ElastiCache node type."
  }
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes in the Redis cluster"
  type        = number
  default     = 1

  validation {
    condition     = var.redis_num_cache_nodes >= 1 && var.redis_num_cache_nodes <= 6
    error_message = "Number of cache nodes must be between 1 and 6."
  }
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.redis_engine_version))
    error_message = "Redis engine version must be in format X.Y."
  }
}

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 7

  validation {
    condition     = var.redis_snapshot_retention_limit >= 0 && var.redis_snapshot_retention_limit <= 35
    error_message = "Snapshot retention limit must be between 0 and 35 days."
  }
}

variable "redis_parameter_group_name" {
  description = "Redis parameter group name"
  type        = string
  default     = "default.redis7"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.redis_parameter_group_name))
    error_message = "Redis parameter group name must be alphanumeric with hyphens."
  }
}

# ============================================
# S3 Bucket Configuration Variables
# ============================================

variable "s3_bucket_name_prefix" {
  description = "Prefix for S3 bucket name (will be appended with random suffix)"
  type        = string
  default     = "sre-project-images"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.s3_bucket_name_prefix))
    error_message = "S3 bucket name prefix must be lowercase alphanumeric with dots and hyphens."
  }
}

variable "s3_versioning_enabled" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_lifecycle_days" {
  description = "Number of days before non-current versions expire"
  type        = number
  default     = 30

  validation {
    condition     = var.s3_lifecycle_days >= 1 && var.s3_lifecycle_days <= 365
    error_message = "Lifecycle days must be between 1 and 365."
  }
}

# ============================================
# ECR Configuration Variables
# ============================================

variable "ecr_image_retention_count" {
  description = "Number of images to retain in ECR repositories"
  type        = number
  default     = 30

  validation {
    condition     = var.ecr_image_retention_count >= 1 && var.ecr_image_retention_count <= 100
    error_message = "ECR image retention count must be between 1 and 100."
  }
}

variable "ecr_untagged_retention_days" {
  description = "Number of days to retain untagged images in ECR"
  type        = number
  default     = 7

  validation {
    condition     = var.ecr_untagged_retention_days >= 1 && var.ecr_untagged_retention_days <= 365
    error_message = "ECR untagged retention days must be between 1 and 365."
  }
}

variable "ecr_image_tag_mutability" {
  description = "ECR image tag mutability"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ECR image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "ecr_scan_on_push" {
  description = "Enable scan on push for ECR repositories"
  type        = bool
  default     = true
}

variable "ecr_encryption_type" {
  description = "Encryption type for ECR repositories"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "KMS"], var.ecr_encryption_type)
    error_message = "ECR encryption type must be either AES256 or KMS."
  }
}

# ============================================
# Kubernetes Addons Configuration Variables
# ============================================

variable "cert_manager_email" {
  description = "Email address for Let's Encrypt certificates"
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.cert_manager_email))
    error_message = "Email address must be valid."
  }
}

variable "route53_hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS validation"
  type        = string
  default     = ""

  validation {
    condition     = var.route53_hosted_zone_id == "" || can(regex("^[A-Z0-9]{14,32}$", var.route53_hosted_zone_id))
    error_message = "Route53 hosted zone ID must be valid."
  }
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for NLB (for Nginx Ingress)"
  type        = string
  default     = ""
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 8
    error_message = "Grafana admin password must be at least 8 characters long."
  }
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for Alertmanager notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_aws_alb_controller" {
  description = "Enable AWS Load Balancer Controller (in addition to Nginx Ingress)"
  type        = bool
  default     = false
}

# ============================================
# External Secrets Configuration Variables
# ============================================

variable "secrets_recovery_window_days" {
  description = "Number of days AWS Secrets Manager waits before it can delete a secret"
  type        = number
  default     = 0

  validation {
    condition     = var.secrets_recovery_window_days >= 0 && var.secrets_recovery_window_days <= 30
    error_message = "Recovery window days must be between 0 and 30."
  }
}

# ============================================
# Monitoring & Alerting Configuration Variables
# ============================================

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus in Gi"
  type        = string
  default     = "50Gi"

  validation {
    condition     = can(regex("^[0-9]+Gi$", var.prometheus_storage_size))
    error_message = "Prometheus storage size must be in format like '50Gi'."
  }
}

variable "prometheus_retention_days" {
  description = "Number of days to retain Prometheus metrics"
  type        = string
  default     = "15d"

  validation {
    condition     = can(regex("^[0-9]+d$", var.prometheus_retention_days))
    error_message = "Prometheus retention must be in format like '15d'."
  }
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana in Gi"
  type        = string
  default     = "10Gi"

  validation {
    condition     = can(regex("^[0-9]+Gi$", var.grafana_storage_size))
    error_message = "Grafana storage size must be in format like '10Gi'."
  }
}

variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager in Gi"
  type        = string
  default     = "10Gi"

  validation {
    condition     = can(regex("^[0-9]+Gi$", var.alertmanager_storage_size))
    error_message = "Alertmanager storage size must be in format like '10Gi'."
  }
}

# ============================================
# Feature Flags
# ============================================

variable "enable_prometheus_stack" {
  description = "Enable Prometheus Stack (Prometheus + Grafana + Alertmanager)"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable Cert Manager for SSL certificates"
  type        = bool
  default     = true
}

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = true
}

variable "enable_nginx_ingress" {
  description = "Enable Nginx Ingress Controller"
  type        = bool
  default     = true
}



variable "enable_metrics_server" {
  description = "Enable Kubernetes Metrics Server"
  type        = bool
  default     = true
}

# ============================================
# Network Configuration Variables
# ============================================

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "vpc_flow_logs_retention_days" {
  description = "Number of days to retain VPC Flow Logs"
  type        = number
  default     = 30

  validation {
    condition     = var.vpc_flow_logs_retention_days >= 1 && var.vpc_flow_logs_retention_days <= 365
    error_message = "VPC Flow Logs retention must be between 1 and 365 days."
  }
}

# ============================================
# Security Configuration Variables
# ============================================

variable "enable_ssh_access" {
  description = "Enable SSH access to EKS worker nodes"
  type        = bool
  default     = false
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_ssh_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All SSH CIDR blocks must be valid CIDR notation."
  }
}



# ============================================
# Backup Configuration Variables
# ============================================

variable "enable_rds_automated_backups" {
  description = "Enable automated backups for RDS"
  type        = bool
  default     = true
}

variable "rds_backup_window" {
  description = "Time window for RDS backups"
  type        = string
  default     = "03:00-06:00"

  validation {
    condition     = can(regex("^[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}$", var.rds_backup_window))
    error_message = "RDS backup window must be in format HH:MM-HH:MM."
  }
}

variable "rds_maintenance_window" {
  description = "Time window for RDS maintenance"
  type        = string
  default     = "Mon:00:00-Mon:03:00"

  validation {
    condition     = can(regex("^[a-zA-Z]{3}:[0-9]{2}:[0-9]{2}-[a-zA-Z]{3}:[0-9]{2}:[0-9]{2}$", var.rds_maintenance_window))
    error_message = "RDS maintenance window must be in format Day:HH:MM-Day:HH:MM."
  }
}

# ============================================
# Domain Configuration Variables
# ============================================

variable "api_domain_name" {
  description = "Domain name for API service"
  type        = string
  default     = "api.staging.example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.api_domain_name))
    error_message = "API domain name must be a valid domain name."
  }
}

variable "auth_domain_name" {
  description = "Domain name for Auth service"
  type        = string
  default     = "auth.staging.example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.auth_domain_name))
    error_message = "Auth domain name must be a valid domain name."
  }
}

variable "image_domain_name" {
  description = "Domain name for Image service"
  type        = string
  default     = "images.staging.example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.image_domain_name))
    error_message = "Image domain name must be a valid domain name."
  }
}

# ============================================
# Cost Optimization Variables
# ============================================

variable "use_spot_instances" {
  description = "Use Spot Instances for EKS worker nodes"
  type        = bool
  default     = false
}

variable "spot_instance_percentage" {
  description = "Percentage of nodes that should be Spot Instances"
  type        = number
  default     = 50

  validation {
    condition     = var.spot_instance_percentage >= 0 && var.spot_instance_percentage <= 100
    error_message = "Spot instance percentage must be between 0 and 100."
  }
}

# ============================================
# Storage Configuration Variables
# ============================================

variable "storage_class_name" {
  description = "Storage class name for dynamic provisioning"
  type        = string
  default     = "gp2"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "sc1", "st1"], var.storage_class_name)
    error_message = "Storage class must be one of: gp2, gp3, io1, io2, sc1, st1."
  }
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption"
  type        = string
  default     = ""
}


# ============================================
# Timezone Configuration
# ============================================

variable "timezone" {
  description = "Timezone for cron jobs and scheduled tasks"
  type        = string
  default     = "UTC"

  validation {
    condition     = contains([
      "UTC", "America/New_York", "America/Chicago", "America/Denver", 
      "America/Los_Angeles", "Europe/London", "Europe/Paris", "Asia/Tokyo",
      "Asia/Singapore", "Australia/Sydney"
    ], var.timezone)
    error_message = "Timezone must be a valid IANA timezone."
  }
}

# ============================================
# Resource Naming Variables
# ============================================

variable "resource_name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "sre"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.resource_name_prefix))
    error_message = "Resource name prefix must be lowercase alphanumeric with hyphens."
  }
}

# ============================================
# Terraform State Configuration
# ============================================

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = ""

  validation {
    condition     = var.terraform_state_bucket == "" || can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.terraform_state_bucket))
    error_message = "Terraform state bucket name must be valid S3 bucket name."
  }
}

variable "terraform_state_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = ""

  validation {
    condition     = var.terraform_state_lock_table == "" || can(regex("^[a-zA-Z0-9_.-]+$", var.terraform_state_lock_table))
    error_message = "Terraform state lock table name must be valid DynamoDB table name."
  }
}