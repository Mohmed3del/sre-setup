
# Data source to get Nginx Ingress Load Balancer
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.nginx_ingress]
}



# Data source to get Grafana service
data "kubernetes_service" "grafana" {
  metadata {
    name      = "prometheus-stack-grafana"
    namespace = "monitoring"
  }

  depends_on = [helm_release.prometheus_stack]
}



# Data source to get Prometheus service
data "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-stack-prometheus"
    namespace = "monitoring"
  }

  depends_on = [helm_release.prometheus_stack]
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}