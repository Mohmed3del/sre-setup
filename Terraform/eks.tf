# ============================================
# EKS Cluster Configuration
# ============================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.eks_cluster_version

  # Enable OIDC provider for IRSA
  enable_irsa = true
  
  # Network configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Security groups
  cluster_additional_security_group_ids = [aws_security_group.eks_cluster.id]
  node_security_group_additional_rules  = local.node_security_group_additional_rules

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # EKS Managed Node Group
  eks_managed_node_groups = {
    main = {
      name            = "main"
      use_name_prefix = false

      ami_type       = "AL2_x86_64"
      capacity_type  = var.use_spot_instances ? "SPOT" : "ON_DEMAND"
      instance_types = [var.eks_node_instance_type]

      min_size     = var.eks_node_min_size
      max_size     = var.eks_node_max_size
      desired_size = var.eks_node_desired_size

      disk_size = var.eks_node_disk_size
      disk_type = var.eks_node_disk_type

      # IAM role with additional policies for IRSA
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy  = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }

      # Labels for nodeSelector
      labels = {
        Environment = var.environment
        NodeGroup   = "main"
        node-group  = "main"
      }

      # Taints for dedicated nodes
      taints = [
        {
          key    = "node-group"
          value  = "main"
          effect = "NO_SCHEDULE"
        }
      ]

      tags = merge(module.tags.tags, {
        Name = "${var.project_name}-${var.environment}-node"
      })
    }
  }

  tags = module.tags.tags
}

# Security Group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.tags.tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
  })
}

# Additional security group rules for nodes
locals {
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

}
# ============================================
# IAM Roles and Policies
# ============================================

# IAM role for EKS node group
data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# CloudWatch Logs policy for EKS
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = module.eks.eks_managed_node_groups["main"].iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Additional policies for EKS nodes
resource "aws_iam_role_policy" "eks_nodes_additional" {
  name = "${var.project_name}-${var.environment}-eks-nodes-additional"
  role = module.eks.eks_managed_node_groups["main"].iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVpcs",
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}