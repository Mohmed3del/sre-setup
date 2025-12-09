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
#
# --------------------------------------------------------------------
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "46.8.0"
  namespace  = "monitoring"
  wait       = true
  timeout    = 600

  depends_on = [kubernetes_namespace.addons["monitoring"]]

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

  # إعدادات Grafana
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

  # إعدادات Prometheus
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

  # Enable additional rules
  set {
    name  = "prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues"
    value = "false"
  }

  values = [
    <<-YAML
    # القواعد المخصصة لكشف الفشل
    prometheus:
      prometheusSpec:
        # القواعد المخصصة
        additionalPrometheusRules:
          - name: microservices-failure-rules
            groups:
              # مجموعة 1: فشل الـ Pods
              - name: pod-failure-detection
                rules:
                  # قاعدة 1: Pod في حالة CrashLoopBackOff
                  - alert: PodCrashLoopBackOff
                    expr: |
                      kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"} > 0
                    for: 2m
                    labels:
                      severity: critical
                      category: pod-failure
                    annotations:
                      summary: "Pod {{ $labels.pod }} is crash looping"
                      description: |
                        Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} 
                        has been crash looping for more than 2 minutes.
                        Container: {{ $labels.container }}
                        Reason: {{ $labels.reason }}
                      action: "Check pod logs: kubectl logs {{ $labels.pod }} -n {{ $labels.namespace }}"
                  
                  # قاعدة 2: Pod غير جاهز
                  - alert: PodNotReady
                    expr: |
                      sum by (namespace, pod) (
                        max by(namespace, pod) (kube_pod_status_phase{phase=~"Pending|Unknown"}) * 
                        on(namespace, pod) group_left(owner_kind) 
                        (kube_pod_owner{owner_kind="ReplicaSet"})
                      ) > 0
                    for: 5m
                    labels:
                      severity: warning
                      category: pod-failure
                    annotations:
                      summary: "Pod {{ $labels.pod }} is not ready"
                      description: |
                        Pod {{ $labels.pod }} in namespace {{ $labels.namespace }}
                        has been in Pending or Unknown state for more than 5 minutes.
                  
                  # قاعدة 3: Pod توقف عن العمل (OOMKilled)
                  - alert: PodOOMKilled
                    expr: |
                      increase(kube_pod_container_status_terminated_reason{reason="OOMKilled"}[5m]) > 0
                    for: 1m
                    labels:
                      severity: critical
                      category: resource-failure
                    annotations:
                      summary: "Pod {{ $labels.pod }} was OOMKilled"
                      description: |
                        Pod {{ $labels.pod }} in namespace {{ $labels.namespace }}
                        was terminated due to OOM (Out Of Memory).
                        Container: {{ $labels.container }}
                      action: "Increase memory limits for the pod"
              
              # مجموعة 2: فشل الخدمات
              - name: service-failure-detection
                rules:
                  # قاعدة 4: Service غير متاح
                  - alert: ServiceDown
                    expr: |
                      up{job="kubernetes-service-endpoints"} == 0
                    for: 3m
                    labels:
                      severity: critical
                      category: service-failure
                    annotations:
                      summary: "Service {{ $labels.service }} is down"
                      description: |
                        Service {{ $labels.service }} in namespace {{ $labels.namespace }}
                        has been down for more than 3 minutes.
                      action: "Check service endpoints: kubectl get endpoints {{ $labels.service }} -n {{ $labels.namespace }}"
                  
                  # قاعدة 5: معدل أخطاء عالي
                  - alert: HighErrorRate
                    expr: |
                      (
                        rate(http_requests_total{status=~"5.."}[5m]) /
                        rate(http_requests_total[5m])
                      ) * 100 > 5
                    for: 2m
                    labels:
                      severity: warning
                      category: service-failure
                    annotations:
                      summary: "High error rate for {{ $labels.service }}"
                      description: |
                        Service {{ $labels.service }} has error rate of {{ $value }}%
                        which is above the 5% threshold.
                      action: "Check service logs and metrics"
                  
                  # قاعدة 6: زمن استجابة عالي
                  - alert: HighLatency
                    expr: |
                      histogram_quantile(0.95, 
                        rate(http_request_duration_seconds_bucket[5m])
                      ) > 1
                    for: 5m
                    labels:
                      severity: warning
                      category: performance
                    annotations:
                      summary: "High latency for {{ $labels.service }}"
                      description: |
                        95th percentile latency for {{ $labels.service }}
                        is {{ $value }} seconds (above 1 second threshold).
              
              # مجموعة 3: فشل الموارد
              - name: resource-failure-detection
                rules:
                  # قاعدة 7: CPU مرتفع جداً
                  - alert: HighCPUUsage
                    expr: |
                      sum(rate(container_cpu_usage_seconds_total[5m])) by (pod, namespace) * 100 > 80
                    for: 5m
                    labels:
                      severity: warning
                      category: resource-failure
                    annotations:
                      summary: "High CPU usage for pod {{ $labels.pod }}"
                      description: |
                        Pod {{ $labels.pod }} in namespace {{ $labels.namespace }}
                        is using {{ $value }}% CPU (above 80% threshold).
                  
                  # قاعدة 8: ذاكرة مرتفعة جداً
                  - alert: HighMemoryUsage
                    expr: |
                      (container_memory_working_set_bytes / container_spec_memory_limit_bytes) * 100 > 85
                    for: 5m
                    labels:
                      severity: warning
                      category: resource-failure
                    annotations:
                      summary: "High memory usage for pod {{ $labels.pod }}"
                      description: |
                        Pod {{ $labels.pod }} in namespace {{ $labels.namespace }}
                        is using {{ $value }}% memory (above 85% threshold).
                  
                  # قاعدة 9: Disk مرتفع
                  - alert: HighDiskUsage
                    expr: |
                      (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100 > 80
                    for: 10m
                    labels:
                      severity: warning
                      category: resource-failure
                    annotations:
                      summary: "High disk usage on node {{ $labels.instance }}"
                      description: |
                        Node {{ $labels.instance }} has {{ $value }}% disk usage
                        (above 80% threshold).
              
              # مجموعة 4: فشل البنية التحتية
              - name: infrastructure-failure-detection
                rules:
                  # قاعدة 10: Node غير صالح
                  - alert: NodeNotReady
                    expr: |
                      kube_node_status_condition{condition="Ready", status="false"} == 1
                    for: 5m
                    labels:
                      severity: critical
                      category: infrastructure-failure
                    annotations:
                      summary: "Node {{ $labels.node }} is not ready"
                      description: |
                        Node {{ $labels.node }} has been not ready for more than 5 minutes.
                      action: "Check node status: kubectl describe node {{ $labels.node }}"
                  
                  # قاعدة 11: عدد Pods غير كافي
                  - alert: InsufficientPods
                    expr: |
                      kube_deployment_status_replicas_available / kube_deployment_spec_replicas * 100 < 50
                    for: 5m
                    labels:
                      severity: warning
                      category: scaling-failure
                    annotations:
                      summary: "Deployment {{ $labels.deployment }} has insufficient pods"
                      description: |
                        Deployment {{ $labels.deployment }} in namespace {{ $labels.namespace }}
                        has only {{ $value }}% of desired pods available.
              
              # مجموعة 5: فشل الاتصال (لخدماتنا المخصصة)
              - name: microservices-connectivity-failure
                rules:
                  # قاعدة 12: فشل الاتصال بـ RDS
                  - alert: DatabaseConnectionFailure
                    expr: |
                      increase(database_connection_errors_total[5m]) > 10
                    for: 2m
                    labels:
                      severity: critical
                      category: connectivity-failure
                    annotations:
                      summary: "Database connection failures detected"
                      description: |
                        {{ $value }} database connection errors in the last 5 minutes.
                        Service: {{ $labels.service }}
                      action: "Check RDS instance status and network connectivity"
                  
                  # قاعدة 13: فشل الاتصال بـ Redis
                  - alert: RedisConnectionFailure
                    expr: |
                      increase(redis_connection_errors_total[5m]) > 5
                    for: 2m
                    labels:
                      severity: critical
                      category: connectivity-failure
                    annotations:
                      summary: "Redis connection failures detected"
                      description: |
                        {{ $value }} Redis connection errors in the last 5 minutes.
                        Service: {{ $labels.service }}
                  
                  # قاعدة 14: فشل الاتصال بـ S3
                  - alert: S3ConnectionFailure
                    expr: |
                      increase(s3_request_errors_total[5m]) > 5
                    for: 2m
                    labels:
                      severity: warning
                      category: connectivity-failure
                    annotations:
                      summary: "S3 connection failures detected"
                      description: |
                        {{ $value }} S3 request errors in the last 5 minutes.
                        Service: {{ $labels.service }}

        # إعدادات جمع Metrics لخدماتنا
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

          # جمع metrics للـ API Gateway (إذا كان موجوداً)
          - job_name: 'nginx-ingress'
            kubernetes_sd_configs:
              - role: pod
                namespaces:
                  names: ['ingress-nginx']
            relabel_configs:
              - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_component]
                action: keep
                regex: controller
              - source_labels: [__meta_kubernetes_pod_container_port_name]
                action: keep
                regex: metrics
        
        # موارد Prometheus
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi

    # إعدادات Grafana
    grafana:
      # لوحات التحكم المسبقة
      sidecar:
        dashboards:
          enabled: true
        datasources:
          enabled: true
      
      # لوحات التحكم المخصصة
      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
            - name: 'microservices'
              orgId: 1
              folder: 'Microservices'
              type: file
              disableDeletion: true
              editable: true
              options:
                path: /var/lib/grafana/dashboards/microservices
      
      # لوحات تحكم مخصصة كـ ConfigMaps
      dashboards:
        microservices:
          api-service-dashboard:
            gnetId: 0
            datasource: Prometheus
            json: |
              {
                "dashboard": {
                  "title": "API Service Dashboard",
                  "panels": [
                    {
                      "title": "HTTP Requests Rate",
                      "type": "graph",
                      "targets": [{
                        "expr": "rate(http_requests_total{service=\"api-service\"}[5m])",
                        "legendFormat": "{{method}} {{endpoint}}"
                      }]
                    }
                  ]
                }
              }
      
      # موارد Grafana
      resources:
        requests:
          cpu: 200m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi

    # إعدادات Alertmanager
    alertmanager:
      alertmanagerSpec:
        # موارد Alertmanager
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 200m
            memory: 512Mi
        
        # تكوين Alertmanager
        config:
          global:
            slack_api_url: '${var.slack_webhook_url}'
            smtp_smarthost: 'smtp.gmail.com:587'
            smtp_from: 'alerts@${var.project_name}.com'
            smtp_auth_username: '${var.alert_email}'
            smtp_auth_password: '${var.alert_email_password}'
          
          route:
            group_by: ['alertname', 'cluster', 'service', 'severity']
            group_wait: 30s
            group_interval: 5m
            repeat_interval: 12h
            receiver: 'default'
            
            routes:
              - match:
                  severity: critical
                receiver: 'slack-critical'
                group_wait: 10s
                repeat_interval: 5m
                continue: true
              
              - match:
                  severity: warning
                receiver: 'slack-warning'
                continue: true
              
              - match:
                  namespace: production
                receiver: 'pager-duty'
                continue: true
          
          receivers:
            - name: 'default'
              email_configs:
                - to: '${var.alert_email}'
                  send_resolved: true
            
            - name: 'slack-critical'
              slack_configs:
                - channel: '#alerts-critical'
                  title: '🚨 [CRITICAL] {{ .GroupLabels.alertname }}'
                  text: |
                    *Alert*: {{ .GroupLabels.alertname }}
                    *Service*: {{ .GroupLabels.service }}
                    *Namespace*: {{ .GroupLabels.namespace }}
                    *Severity*: {{ .GroupLabels.severity }}
                    *Description*: {{ .CommonAnnotations.description }}
                    *Action*: {{ .CommonAnnotations.action }}
                  send_resolved: true
            
            - name: 'slack-warning'
              slack_configs:
                - channel: '#alerts-warning'
                  title: '⚠️ [WARNING] {{ .GroupLabels.alertname }}'
                  text: |
                    *Alert*: {{ .GroupLabels.alertname }}
                    *Service*: {{ .GroupLabels.service }}
                    *Description*: {{ .CommonAnnotations.description }}
                  send_resolved: true
            
            - name: 'pager-duty'
              pagerduty_configs:
                - service_key: '${var.pagerduty_service_key}'
                  description: '{{ .CommonAnnotations.summary }}'
                  details:
                    alert: '{{ .GroupLabels.alertname }}'
                    service: '{{ .GroupLabels.service }}'
                    namespace: '{{ .GroupLabels.namespace }}'
    YAML
  ]
}

# --------------------------------------------------------------------
# ConfigMaps للوحات تحكم إضافية
# --------------------------------------------------------------------
resource "kubernetes_config_map" "microservices_dashboards" {
  metadata {
    name      = "microservices-dashboards"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = "true"
    }
  }

  data = {
    "api-service.json" = jsonencode({
      dashboard = {
        title = "API Service Dashboard"
        panels = [
          {
            title = "HTTP Requests Rate"
            type = "graph"
            targets = [{
              expr = "rate(http_requests_total{service=\"api-service\"}[5m])"
              legendFormat = "{{method}} {{endpoint}}"
            }]
          },
          {
            title = "Error Rate"
            type = "stat"
            targets = [{
              expr = "rate(http_requests_total{status=~\"5..\",service=\"api-service\"}[5m]) / rate(http_requests_total{service=\"api-service\"}[5m]) * 100"
              legendFormat = "Error Rate"
            }]
          }
        ]
      }
    })
    
    "system-overview.json" = jsonencode({
      dashboard = {
        title = "System Overview"
        panels = [
          {
            title = "CPU Usage"
            type = "graph"
            targets = [{
              expr = "sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace) * 100"
            }]
          },
          {
            title = "Memory Usage"
            type = "graph"
            targets = [{
              expr = "sum(container_memory_working_set_bytes) by (namespace) / 1024 / 1024 / 1024"
              legendFormat = "{{namespace}} GB"
            }]
          }
        ]
      }
    })
  }

  depends_on = [helm_release.prometheus_stack]
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

