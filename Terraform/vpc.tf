# ============================================
# VPC Configuration
# ============================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-${var.environment}"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # Database subnets
  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  database_subnets                   = var.database_subnet_cidrs

  # NAT Gateway for private subnets
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = var.enable_vpc_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_vpc_flow_logs
  create_flow_log_cloudwatch_iam_role  = var.enable_vpc_flow_logs
  flow_log_max_aggregation_interval    = 60
  flow_log_destination_type            = "cloud-watch-logs"
  flow_log_log_format                  = "$${version} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${account-id} $${type} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${pkt-srcaddr} $${pkt-dstaddr} $${protocol} $${bytes} $${packets} $${start} $${end} $${action} $${log-status}"

  tags = module.tags.tags

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
    "karpenter.sh/discovery"                    = var.project_name
  }

  database_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  }
}

# Security Group for EKS worker nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.tags.tags, {
    Name = "${var.project_name}-${var.environment}-eks-nodes-sg"
  })
}

# Allow SSH access if enabled
resource "aws_security_group_rule" "eks_nodes_ssh" {
  count = var.enable_ssh_access ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidr_blocks
  security_group_id = aws_security_group.eks_nodes.id
  description       = "SSH access to EKS worker nodes"
}

# Allow all traffic within the security group
resource "aws_security_group_rule" "eks_nodes_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow all traffic within the security group"
}