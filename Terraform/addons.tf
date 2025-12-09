# ============================================
# Kubernetes Addons using Helm Provider
# ============================================

# Create namespaces for addons
resource "kubernetes_namespace" "addons" {
  for_each = toset([
    "external-secrets",
    "cert-manager",
    "ingress-nginx",
    "monitoring"
  ])

  metadata {
    name = each.key
    labels = {
      name        = each.key
      environment = var.environment
      project     = var.project_name
    }
  }
}

# --------------------------------------------------------------------
# 1. External Secrets Operator
# --------------------------------------------------------------------
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.0"
  namespace  = "external-secrets"
  wait       = true
  timeout    = 300

  # Create namespace if it doesn't exist
  depends_on = [kubernetes_namespace.addons["external-secrets"]]

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_external_secrets.iam_role_arn
  }

  set {
    name  = "replicaCount"
    value = "2"
  }

  # Resource limits
  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  # Enable Prometheus metrics
  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "metrics.serviceMonitor.enabled"
    value = "true"
  }

  values = [
    <<-YAML
    webhook:
      replicas: 2
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi
    
    certController:
      replicas: 2
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi
    YAML
  ]
}

# --------------------------------------------------------------------
# 2. Cert Manager
# --------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.2"
  namespace  = "cert-manager"
  wait       = true
  timeout    = 300

  # Create namespace if it doesn't exist
  depends_on = [kubernetes_namespace.addons["cert-manager"]]

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "cert-manager"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_cert_manager.iam_role_arn
  }

  set {
    name  = "replicaCount"
    value = "2"
  }

  # Resource limits
  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  # Prometheus metrics
  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.servicemonitor.enabled"
    value = "true"
  }

  values = [
    <<-YAML
    webhook:
      replicas: 2
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi
    
    cainjector:
      replicas: 2
      resources:
        limits:
          cpu: 100m
          memory: 128Mi
        requests:
          cpu: 50m
          memory: 64Mi
    
    startupapicheck:
      timeout: "5m"
      resources:
        limits:
          cpu: 10m
          memory: 64Mi
        requests:
          cpu: 10m
          memory: 64Mi
    YAML
  ]
}

# Create ClusterIssuer for Let's Encrypt
resource "kubernetes_manifest" "cluster_issuer_staging" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        solvers = [{
          dns01 = {
            route53 = {
              region = var.aws_region
              hostedZoneID = var.route53_hosted_zone_id
            }
          }
        }]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "cluster_issuer_production" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-production"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email
        privateKeySecretRef = {
          name = "letsencrypt-production"
        }
        solvers = [{
          dns01 = {
            route53 = {
              region = var.aws_region
              hostedZoneID = var.route53_hosted_zone_id
            }
          }
        }]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# --------------------------------------------------------------------
# 3. Nginx Ingress Controller
# --------------------------------------------------------------------
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.1"
  namespace  = "ingress-nginx"
  wait       = true
  timeout    = 300

  # Create namespace if it doesn't exist
  depends_on = [kubernetes_namespace.addons["ingress-nginx"]]

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "tcp"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = var.ssl_certificate_arn
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "https"
  }

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = "nginx-ingress"
  }

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_nginx_ingress.iam_role_arn
  }

  # Resource limits
  set {
    name  = "controller.resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "controller.resources.limits.memory"
    value = "512Mi"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "256Mi"
  }

  # Enable metrics
  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }

  # Enable Prometheus rules
  set {
    name  = "controller.metrics.prometheusRule.enabled"
    value = "true"
  }

  values = [
    <<-YAML
    controller:
      config:
        use-forwarded-headers: "true"
        compute-full-forwarded-for: "true"
        use-proxy-protocol: "true"
        enable-underscores-in-headers: "true"
        ssl-protocols: "TLSv1.2 TLSv1.3"
        ssl-ciphers: "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256"
      
      podAnnotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "10254"
      
      nodeSelector:
        node-group: main
      
      tolerations:
        - key: "node-group"
          operator: "Equal"
          value: "main"
          effect: "NoSchedule"
      
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchExpressions:
                    - key: app.kubernetes.io/name
                      operator: In
                      values:
                        - ingress-nginx
                    - key: app.kubernetes.io/component
                      operator: In
                      values:
                        - controller
                topologyKey: kubernetes.io/hostname
    YAML
  ]
}

# --------------------------------------------------------------------
# 4. Prometheus Stack (Prometheus + Grafana + Alertmanager)
# --------------------------------------------------------------------
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "46.8.0"
  namespace  = "monitoring"
  wait       = true
  timeout    = 600

  # Create namespace if it doesn't exist
  depends_on = [kubernetes_namespace.addons["monitoring"]]

  # Disable some default components we don't need
  set {
    name  = "defaultRules.create"
    value = "true"
  }

  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  # Grafana configuration
  set {
    name  = "grafana.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "grafana.serviceAccount.name"
    value = "grafana"
  }

  set {
    name  = "grafana.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_grafana.iam_role_arn
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = "gp2"
  }

  # Prometheus configuration
  set {
    name  = "prometheus.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "prometheus.serviceAccount.name"
    value = "prometheus"
  }

  set {
    name  = "prometheus.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_prometheus.iam_role_arn
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp2"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "50Gi"
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "15d"
  }

  set {
    name  = "prometheus.prometheusSpec.replicaCount"
    value = "2"
  }

  # Alertmanager configuration
  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = "gp2"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = "10Gi"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.replicaCount"
    value = "2"
  }

  values = [
    <<-YAML
    # Additional scrape configs for our services
    prometheus:
      prometheusSpec:
        additionalScrapeConfigs:
          - job_name: 'microservices'
            kubernetes_sd_configs:
              - role: pod
            relabel_configs:
              - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
                action: keep
                regex: true
              - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
                action: replace
                target_label: __metrics_path__
                regex: (.+)
              - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
                action: replace
                regex: ([^:]+)(?::\d+)?;(\d+)
                replacement: $1:$2
                target_label: __address__
              - action: labelmap
                regex: __meta_kubernetes_pod_label_(.+)
              - source_labels: [__meta_kubernetes_namespace]
                action: replace
                target_label: namespace
              - source_labels: [__meta_kubernetes_pod_name]
                action: replace
                target_label: pod
        
        # Resource limits
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
    
    # Grafana dashboards
    grafana:
      # Preconfigured dashboards
      sidecar:
        dashboards:
          enabled: true
          label: grafana_dashboard
      
      
      # Resource limits
      resources:
        requests:
          cpu: 200m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
    
    # Alertmanager config
    alertmanager:
      alertmanagerSpec:
        # Resource limits
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 200m
            memory: 512Mi
        
        # Alertmanager configuration
        config:
          global:
            slack_api_url: '${var.slack_webhook_url}'
          route:
            group_by: ['alertname', 'cluster', 'service']
            group_wait: 30s
            group_interval: 5m
            repeat_interval: 12h
            receiver: 'slack-notifications'
            routes:
              - match:
                  severity: critical
                receiver: 'slack-critical'
                continue: true
              - match:
                  severity: warning
                receiver: 'slack-warning'
                continue: true
          receivers:
            - name: 'slack-notifications'
              slack_configs:
                - channel: '#alerts'
                  title: '{{ template "slack.default.title" . }}'
                  text: '{{ template "slack.default.text" . }}'
                  send_resolved: true
            - name: 'slack-critical'
              slack_configs:
                - channel: '#alerts-critical'
                  title: '🚨 {{ template "slack.default.title" . }}'
                  text: '{{ template "slack.default.text" . }}'
                  send_resolved: true
            - name: 'slack-warning'
              slack_configs:
                - channel: '#alerts-warning'
                  title: '⚠️ {{ template "slack.default.title" . }}'
                  text: '{{ template "slack.default.text" . }}'
                  send_resolved: true
    YAML
  ]
}

# --------------------------------------------------------------------
# 5. AWS Load Balancer Controller (Optional - if needed)
# --------------------------------------------------------------------
resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_alb_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.1"
  namespace  = "kube-system"
  wait       = true
  timeout    = 300

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_nginx_ingress.iam_role_arn # Reuse the same role
  }

  set {
    name  = "replicaCount"
    value = "2"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "enableServiceMutatorWebhook"
    value = "false"
  }

  values = [
    <<-YAML
    # Enable Prometheus metrics
    metrics:
      enabled: true
      serviceMonitor:
        enabled: true
    
    # Pod affinity
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                  - key: app.kubernetes.io/name
                    operator: In
                    values:
                      - aws-load-balancer-controller
              topologyKey: kubernetes.io/hostname
    YAML
  ]
}

# --------------------------------------------------------------------
# 6. Kubernetes Metrics Server
# --------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.10.0"
  namespace  = "kube-system"
  wait       = true
  timeout    = 300

  set {
    name  = "apiService.create"
    value = "true"
  }

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  set {
    name  = "replicas"
    value = "2"
  }

  set {
    name  = "resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }
}

