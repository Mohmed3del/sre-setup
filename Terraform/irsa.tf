# ============================================
# IRSA Roles using terraform-aws-iam/modules/irsa
# ============================================

module "irsa_external_secrets" {
  source  = "terraform-aws-iam/modules/irsa/aws"
  version = "~> 1.0"

  create_role                   = true
  role_name                    = "${var.project_name}-${var.environment}-external-secrets"
  role_path                    = "/${var.project_name}/${var.environment}/"
  role_description             = "IRSA role for External Secrets Operator"
  role_permissions_boundary_arn = null

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  # Policies
  policies = {
    SecretsManagerAccess = {
      description = "Access to Secrets Manager"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret",
              "secretsmanager:ListSecrets"
            ]
            Resource = [
              aws_secretsmanager_secret.database.arn,
              aws_secretsmanager_secret.redis.arn,
              aws_secretsmanager_secret.s3.arn,
              aws_secretsmanager_secret.services.arn,
              "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:/${var.project_name}/${var.environment}/*"
            ]
          }
        ]
      })
    }
  }

  tags = module.tags.tags
}

module "irsa_cert_manager" {
  source  = "terraform-aws-iam/modules/irsa/aws"
  version = "~> 1.0"

  create_role                   = true
  role_name                    = "${var.project_name}-${var.environment}-cert-manager"
  role_path                    = "/${var.project_name}/${var.environment}/"
  role_description             = "IRSA role for Cert Manager"
  role_permissions_boundary_arn = null

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }

  # Policies for Route53 DNS validation
  policies = {
    Route53Access = {
      description = "Access to Route53 for DNS validation"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "route53:GetChange",
              "route53:ChangeResourceRecordSets",
              "route53:ListResourceRecordSets"
            ]
            Resource = [
              "arn:aws:route53:::hostedzone/*",
              "arn:aws:route53:::change/*"
            ]
          },
          {
            Effect = "Allow"
            Action = "route53:ListHostedZonesByName"
            Resource = "*"
          }
        ]
      })
    }
  }

  tags = module.tags.tags
}

module "irsa_nginx_ingress" {
  source  = "terraform-aws-iam/modules/irsa/aws"
  version = "~> 1.0"

  create_role                   = true
  role_name                    = "${var.project_name}-${var.environment}-nginx-ingress"
  role_path                    = "/${var.project_name}/${var.environment}/"
  role_description             = "IRSA role for Nginx Ingress Controller"
  role_permissions_boundary_arn = null

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["ingress-nginx:nginx-ingress"]
    }
  }

  # Policies for Nginx Ingress
  policies = {
    ELBAccess = {
      description = "Access to manage ELB resources"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "acm:DescribeCertificate",
              "acm:ListCertificates",
              "acm:GetCertificate",
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:CreateSecurityGroup",
              "ec2:CreateTags",
              "ec2:DeleteTags",
              "ec2:DeleteSecurityGroup",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeAddresses",
              "ec2:DescribeInstances",
              "ec2:DescribeInstanceStatus",
              "ec2:DescribeInternetGateways",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeSubnets",
              "ec2:DescribeTags",
              "ec2:DescribeVpcs",
              "ec2:ModifyInstanceAttribute",
              "ec2:ModifyNetworkInterfaceAttribute",
              "ec2:RevokeSecurityGroupIngress",
              "elasticloadbalancing:AddListenerCertificates",
              "elasticloadbalancing:AddTags",
              "elasticloadbalancing:CreateListener",
              "elasticloadbalancing:CreateLoadBalancer",
              "elasticloadbalancing:CreateRule",
              "elasticloadbalancing:CreateTargetGroup",
              "elasticloadbalancing:DeleteListener",
              "elasticloadbalancing:DeleteLoadBalancer",
              "elasticloadbalancing:DeleteRule",
              "elasticloadbalancing:DeleteTargetGroup",
              "elasticloadbalancing:DeregisterTargets",
              "elasticloadbalancing:DescribeListenerCertificates",
              "elasticloadbalancing:DescribeListeners",
              "elasticloadbalancing:DescribeLoadBalancers",
              "elasticloadbalancing:DescribeLoadBalancerAttributes",
              "elasticloadbalancing:DescribeRules",
              "elasticloadbalancing:DescribeSSLPolicies",
              "elasticloadbalancing:DescribeTags",
              "elasticloadbalancing:DescribeTargetGroups",
              "elasticloadbalancing:DescribeTargetHealth",
              "elasticloadbalancing:ModifyListener",
              "elasticloadbalancing:ModifyLoadBalancerAttributes",
              "elasticloadbalancing:ModifyRule",
              "elasticloadbalancing:ModifyTargetGroup",
              "elasticloadbalancing:ModifyTargetGroupAttributes",
              "elasticloadbalancing:RegisterTargets",
              "elasticloadbalancing:RemoveListenerCertificates",
              "elasticloadbalancing:RemoveTags",
              "elasticloadbalancing:SetIpAddressType",
              "elasticloadbalancing:SetSecurityGroups",
              "elasticloadbalancing:SetSubnets",
              "elasticloadbalancing:SetWebAcl",
              "iam:CreateServiceLinkedRole",
              "iam:GetServerCertificate",
              "iam:ListServerCertificates",
              "waf:GetWebACL",
              "waf-regional:GetWebACLForResource",
              "waf-regional:GetWebACL",
              "waf-regional:AssociateWebACL",
              "waf-regional:DisassociateWebACL",
              "wafv2:GetWebACL",
              "wafv2:GetWebACLForResource",
              "wafv2:AssociateWebACL",
              "wafv2:DisassociateWebACL",
              "tag:GetResources",
              "tag:TagResources"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }

  tags = module.tags.tags
}

module "irsa_prometheus" {
  source  = "terraform-aws-iam/modules/irsa/aws"
  version = "~> 1.0"

  create_role                   = true
  role_name                    = "${var.project_name}-${var.environment}-prometheus"
  role_path                    = "/${var.project_name}/${var.environment}/"
  role_description             = "IRSA role for Prometheus"
  role_permissions_boundary_arn = null

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["monitoring:prometheus"]
    }
  }

  # Policies for CloudWatch metrics
  policies = {
    CloudWatchAccess = {
      description = "Access to CloudWatch metrics"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "cloudwatch:ListMetrics",
              "cloudwatch:GetMetricData",
              "cloudwatch:GetMetricStatistics",
              "cloudwatch:DescribeAlarms",
              "tag:GetResources"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = "logs:DescribeLogGroups"
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "logs:DescribeLogStreams",
              "logs:GetLogEvents",
              "logs:FilterLogEvents"
            ]
            Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        ]
      })
    }
  }

  tags = module.tags.tags
}

module "irsa_grafana" {
  source  = "terraform-aws-iam/modules/irsa/aws"
  version = "~> 1.0"

  create_role                   = true
  role_name                    = "${var.project_name}-${var.environment}-grafana"
  role_path                    = "/${var.project_name}/${var.environment}/"
  role_description             = "IRSA role for Grafana"
  role_permissions_boundary_arn = null

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["monitoring:grafana"]
    }
  }

  # Policies for CloudWatch and S3 access
  policies = {
    MonitoringAccess = {
      description = "Access to monitoring resources"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "cloudwatch:DescribeAlarms",
              "cloudwatch:GetMetricData",
              "cloudwatch:ListMetrics",
              "ec2:DescribeTags",
              "ec2:DescribeInstances",
              "ec2:DescribeRegions"
            ]
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = "logs:DescribeLogGroups"
            Resource = "*"
          },
          {
            Effect = "Allow"
            Action = [
              "logs:DescribeLogStreams",
              "logs:GetLogEvents"
            ]
            Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        ]
      })
    }
  }

  tags = module.tags.tags
}


