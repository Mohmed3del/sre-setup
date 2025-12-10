# SRE Microservices Platform Project

## 📋 Table of Contents

- [📘 Project Overview](#project-overview)
- [🏗️ System Architecture](#system-architecture)
- [☁️ AWS Infrastructure Architecture](#aws-infrastructure-architecture)
- [🧰 Prerequisites](#prerequisites)
- [⚡ Quick Start](#quick-start)
- [🏗️ Infrastructure Setup](#infrastructure-setup)
- [🚢 Application Deployment](#application-deployment)
- [🔄 CI/CD Pipeline](#cicd-pipeline)
- [📊 Monitoring & Observability](#monitoring--observability)
- [🧪 Failure Testing](#failure-testing)
- [🔒 Security](#security)
- [🧠 Troubleshooting](#troubleshooting)
- [🛠️ Service Details](#service-details)
- [🤝 Contributing](#contributing)
- [📌 Project Status](#project-status)
- [📄 License](#license)


---

## Project Overview

This project demonstrates a **complete SRE-grade production microservices environment** deployed on **AWS EKS**, including:

- Multi-language microservices (Node.js, Go, Python)
- Managed AWS services (RDS, S3, Redis, Secrets Manager)
- GitHub Actions CI/CD
- Terraform Infrastructure as Code
- Observability stack (Prometheus, Grafana, Alertmanager)
- Network isolation + IAM security
- Failure testing & resiliency validation

---

## System Architecture


```yaml
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS EKS Cluster                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐                  │
│  │   API       │      │   Auth      │      │   Image     │                  │
│  │  Service    │◄────►│  Service    │◄────►│  Service    │                  │
│  │ (Node.js)   │      │   (Go)      │      │  (Python)   │                  │
│  └─────────────┘      └─────────────┘      └─────────────┘                  │
│         │                    │                    │                         │
│         ▼                    ▼                    ▼                         │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │                    Network Policies                         │            │
│  │        (Isolated communication with least privilege)        │            │
│  └─────────────────────────────────────────────────────────────┘            │
│         │                    │                    │                         │
│         ▼                    ▼                    ▼                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   RDS       │  │   Redis     │  │     S3      │  │ Secrets     │         │
│  │ PostgreSQL  │  │ ElastiCache │  │ (Images)    │  │ Manager     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                          Observability Stack                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────────┐   │
│  │ Prometheus  │  │  Grafana    │  │ Alertmanager│  │  Nginx Controller │   │
│  │  (Metrics)  │  │ (Dashboards)│  │  (Alerts)   │  │    (Ingress)      │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └───────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## AWS Infrastructure Architecture
![Diagram of Project](infra.drawio.svg)

---

## Prerequisites

### Required Tools

- `Terraform 1.5+`
- `kubectl`
- `Helm 3.8+`
- `AWS CLI`
- `Docker`
- `Git`

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`
- `AWS_REGION`
- `EKS_CLUSTER_NAME`

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/Mohmed3del/sre-setup
cd sre-setup
```



### 2. Configure AWS

```bash
aws configure
```

### 3. Deploy infrastructure

```bash
./infra_setup.sh
```

Or manually:

```bash
cd Terraform
terraform init
terraform apply
```

### 4. Deploy applications

```bash
kubectl apply -k ./Charts/values/api-service
```

---

## Infrastructure Setup

Terraform provisions:

- VPC + subnets
- EKS Cluster
- Managed node groups
- RDS PostgreSQL
- ElastiCache Redis
- S3 bucket
- ECR repositories
- ALB Ingress Controller
- Prometheus/Grafana stack
- External Secrets Operator
- IAM Roles for Service Accounts (IRSA)

---

## Application Deployment

### Microservices

| Service       | Lang    | Port | Purpose          | Depends On |
| ------------- | ------- | ---- | ---------------- | ---------- |
| API Service   | Node.js | 8080 | Main gateway     | Redis      |
| Auth Service  | Go      | 8080 | Authentication   | PostgreSQL |
| Image Service | Python  | 8080 | Image processing | S3         |

### Deploy using Helm

```bash
helm upgrade --install api-service ./Charts/microservice-template \
  -n production -f ./Charts/values/api-service/values.yaml
```

---

## CI/CD Pipeline

CI/CD workflow:
`.github/workflows/deploy.yml`

Features:

- Build & push Docker images
- Deploy updated services
- Rollout verification
- Automatic triggers on code change

Manual run:
GitHub → Actions → **Build & Deploy**

---

## Monitoring & Observability

Stack includes:

- **Prometheus**
- **Grafana**
- **Alertmanager**

Grafana password:

```bash
kubectl get secret prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 --decode
```

Expose Grafana locally:

```bash
kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring
```

---

## Failure Testing

Run:

```bash
./scripts/run-failure-tests.sh production api-service
```

Test Scenarios:

- Pod crash
- Node failure
- OOMKill
- Latency injection
- DB failure
- HPA stress test

---

## Security

Includes:

- AWS Secrets Manager + ESO
- IRSA
- Kubernetes RBAC
- Network Policies
- Non-root Docker images
- Resource limits

---

## Troubleshooting

Common commands:

```bash
kubectl get pods -A
kubectl logs <pod>
kubectl describe pod <pod>
```

Helm status:

```bash
helm status api-service -n production
```

---

## Service Details

### API Service

- `/health`
- `/ready`
- `/metrics`
- Calls Auth & Image services

### Auth Service

- JWT generation
- PostgreSQL integration

### Image Service

- Upload to S3
- Transform / resize

---

##  Contributing

1. Fork repository
2. Create feature branch
3. Add tests
4. Open PR

Coding guidelines:

- Terraform formatted
- Helm lint clean
- Security best practices

---

## Project Status

### ✅ Completed

- Infrastructure
- Deployment
- Monitoring
- Security
- Failure testing

### 🔄 In Progress

- Load testing
- Cost analysis

### 🚀 Future Enhancements

- Istio / Linkerd
- ArgoCD GitOps
- Multi-region HA

---

## 📄 License

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Visitors](https://visitor-badge.laobi.icu/badge?page_id=Mohmed3del.sre-setup)
![GitHub stars](https://img.shields.io/github/stars/Mohmed3del/sre-setup?style=social)
![GitHub forks](https://img.shields.io/github/forks/Mohmed3del/sre-setup?style=social)
