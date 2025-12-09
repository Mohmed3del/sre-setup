terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket         = "sre-project-tfstate-${var.environment}"
    key            = "terraform/state"
    region         = var.aws_region
    encrypt        = true
    dynamodb_table = "sre-project-tfstate-lock-${var.environment}"
  }
}

# Generate random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# Tags module
module "tags" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git?ref=0.25.0"

  namespace   = "sre"
  environment = var.environment
  name        = var.project_name
  delimiter   = "-"
  label_order = ["namespace", "environment", "name"]
  tags        = var.tags
}