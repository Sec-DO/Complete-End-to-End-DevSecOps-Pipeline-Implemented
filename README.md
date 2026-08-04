# SecDO – Automated CI/CD & Security Compliance Pipeline

[![DevSecOps](https://img.shields.io/badge/DevSecOps-Automated%20Pipeline-blue.svg)](https://github.com/therahulpatil/Module1-ProgrammingConcepts)
[![AWS ECR](https://img.shields.io/badge/AWS-ECR%20%26%20EC2-orange.svg)](https://aws.amazon.com/)
[![Jenkins](https://img.shields.io/badge/Jenkins-18--Stage%20Pipeline-red.svg)](https://www.jenkins.io/)
[![SonarQube](https://img.shields.io/badge/Security-SonarQube%20%26%20Trivy-green.svg)](https://www.sonarqube.org/)

**SecDO** is an enterprise-grade DevSecOps pipeline designed for cloud applications deployed on AWS. It automates static code security analysis (SAST), software supply chain auditing (Trivy), multi-stage Docker containerization, keyless AWS ECR registry pushes via IAM Instance Profiles (`aws sts get-caller-identity`), zero-downtime EC2 deployment, automated healthprobe probes with instant failure rollback, and real-time observability using Prometheus, Grafana, Node Exporter, and cAdvisor.

---

## 🏗️ Architecture & Network Design

```
+---------------------------------------------------------------------------------------------------+
|                                      AWS Custom VPC (10.0.0.0/16)                                 |
|                                                                                                   |
|  +-------------------------------------------+   +---------------------------------------------+  |
|  |           Public Subnet 1a (10.0.1.0/24)  |   |             Public Subnet 1b (10.0.2.0/24)   |  |
|  |                                           |   |                                             |  |
|  |  +-------------------------------------+  |   |  +---------------------------------------+  |  |
|  |  |      Jenkins CI/CD EC2 Instance     |  |   |  |     Application & Monitoring Host     |  |  |
|  |  |  - Jenkins Engine (8080)             |  |   |  |  - SecDO App Stack (80/443)             |  |  |
|  |  |  - SonarQube SAST (9000)            |  |   |  |  - Prometheus Telemetry (9090)        |  |  |
|  |  |  - Trivy Security Scanner           |  |   |  |  - Grafana Dashboards (3000)          |  |  |
|  |  |  - IAM Instance Profile Attached    |  |   |  |  - cAdvisor (8081) / Node Exporter    |  |  |
|  |  +-------------------------------------+  |   |  +---------------------------------------+  |  |
|  +-------------------------------------------+   +---------------------------------------------+  |
|                        |                                                |                         |
|                        +-----------------------+------------------------+                         |
|                                                |                                                  |
|                        +-----------------------v------------------------+                         |
|                        |       Internet Gateway (0.0.0.0/0)             |                         |
|                        +------------------------------------------------+                         |
+---------------------------------------------------------------------------------------------------+
```

---

## 🚀 Key Features

1. **Keyless AWS IAM Authentication**: Zero hardcoded access keys. Uses AWS STS (`aws sts get-caller-identity`) and IAM Instance Profiles.
2. **Comprehensive SAST & Vulnerability Auditing**: Integrated SonarQube Quality Gates and Trivy filesystem/container image scanning.
3. **Multi-Stage Container Hardening**: PHP 8.3 Apache container execution restricted under non-root `www-data` unprivileged user.
4. **Automated Zero-Downtime Rollback**: `health-check.sh` polls the `/health.php` endpoint after deployment. If probes fail, `rollback.sh` immediately falls back to the previous stable image tag.
5. **Full Observability Stack**: Real-time CPU, memory, disk, network, and container telemetry via Prometheus + Grafana.

---

## 🔄 18-Stage CI/CD Security Pipeline

| Stage # | Stage Name | Description |
| :--- | :--- | :--- |
| **1** | Checkout | Pulls latest code & extracts Git Commit SHA |
| **2** | Build & Syntax Check | Validates PHP codebase syntax (`php -l`) |
| **3** | Unit Verification | Executes unit validation probes |
| **4** | SonarQube SAST | Performs static application security testing |
| **5** | Quality Gate Check | Evaluates SonarQube security rules & thresholds |
| **6** | Trivy Filesystem Scan | Audits repository files for secrets & vulnerabilities |
| **7** | Docker Multi-Stage Build | Builds production hardened container images |
| **8** | Trivy Image Scan | Scans container layers for HIGH/CRITICAL CVEs |
| **9** | ECR Login (Keyless) | Obtains short-lived IAM STS token via `aws ecr get-login-password` |
| **10** | Push to ECR | Pushes `latest`, `BUILD_NUMBER`, and `GIT_COMMIT` image tags |
| **11** | SSH Setup | Establishes encrypted SSH session to target host |
| **12** | ECR Pull | Pulls target container images on Application server |
| **13** | Compose Deployment | Updates container services via `docker-compose-ecr.yml` |
| **14** | Health Probe Check | Polls `/health.php` endpoint up to 10 retries |
| **15** | Automated Rollback | Triggered automatically on probe failure |
| **16** | Workspace Cleanup | Prunes dangling Docker image layers |
| **17** | Success Notification | Logs successful pipeline execution details |
| **18** | Failure Alert Hook | Configured for Slack/Email alert dispatch |

---

## 🛠️ Quick Start & Setup Guide

### 1. Infrastructure Provisioning via Terraform
```bash
cd SecDO/terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### 2. Local Stack Execution (Development)
```bash
docker compose -f deployment/docker-compose.yml up -d --build
curl -i http://localhost/health.php
```

### 3. Monitoring Stack Execution
```bash
docker compose -f monitoring/docker-compose-monitoring.yml up -d
```
Access Grafana at `http://<APP_HOST_IP>:3000` (Default credentials: `admin` / `admin_secdo_monitoring`).

---

## 🛡️ Security Compliance Standards

- **Zero Secret Sprawl**: Secret keys are never stored in repositories or Jenkins credentials text.
- **OWASP HTTP Security Headers**: Implemented in `backend/src/index.php`.
- **Least Privilege Execution**: Docker containers switch to `USER www-data`.
- **Least Privilege IAM**: Jenkins IAM Role restricted strictly to necessary ECR & EC2 operations.

---

## 📜 License
Developed for enterprise CDAC / DevSecOps engineering portfolio demonstrations.
