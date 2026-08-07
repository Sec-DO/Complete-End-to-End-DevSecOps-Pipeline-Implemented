# SecDO – End-to-End Enterprise DevSecOps & Cloud Compliance Platform

[![DevSecOps](https://img.shields.io/badge/DevSecOps-Automated%20Pipeline-blue.svg)](https://github.com/Sec-DO/Complete-End-to-End-DevSecOps-Pipeline-Implemented.git)
[![AWS Infrastructure](https://img.shields.io/badge/AWS-ECR%20%7C%20EC2%20%7C%20ALB-orange.svg)](https://aws.amazon.com/)
[![Jenkins](https://img.shields.io/badge/Jenkins-Automated%20CI%2FCD-red.svg)](https://www.jenkins.io/)
[![Security Audits](https://img.shields.io/badge/Security-SonarQube%20%7C%20Trivy%20%7C%20OWASP%20ZAP%20%7C%20Prowler%20v4-green.svg)](https://www.sonarqube.org/)

**SecDO** is a production-ready, enterprise-grade DevSecOps platform and Cloud Security Posture Management (CSPM) system built on AWS. It automates static application security testing (SonarQube SAST), software supply chain vulnerability audits (Aqua Trivy FS & Image), multi-stage Docker containerization, keyless AWS ECR registry authentication via IAM Instance Profiles, Docker Swarm cluster deployments, dynamic security testing (OWASP ZAP DAST), real-time observability (Prometheus + Grafana + cAdvisor + Node Exporter), and deep AWS cloud infrastructure compliance auditing (Checkov + tfsec + Gitleaks + Prowler v4).

---

## 🌐 Live System Infrastructure Matrix

| Service | Access URL / Details | Protocol / Port |
| :--- | :--- | :--- |
| **Production Web App** | `http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com` | HTTP / `80` |
| **Healthprobe Readiness API** | `http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com/health.php` | HTTP / `80` |
| **Jenkins CI/CD Server** | `http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:8080` | HTTP / `8080` |
| **SonarQube SAST Server** | `http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:9000` | HTTP / `9000` |
| **Grafana Observability** | `http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:3000` | HTTP / `3000` |
| **Prometheus Telemetry** | `http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:9090` | HTTP / `9090` |
| **cAdvisor Container Engine** | `http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:8081` | HTTP / `8081` |
| **AWS Private ECR Registry** | `325698037625.dkr.ecr.ap-south-1.amazonaws.com/secdo-ecr` | Docker TLS ||

---

## 🏗️ Architecture & AWS Topology

```
+---------------------------------------------------------------------------------------------------+
|                                 AWS Custom VPC (10.0.0.0/16) - ap-south-1                         |
|                                                                                                   |
|  +-------------------------------------------+   +---------------------------------------------+  |
|  |       Public Subnet 1a (10.0.10.0/24)     |   |       Public Subnet 1b (10.0.20.0/24)     |  |
|  |                                           |   |                                             |  |
|  |  +-------------------------------------+  |   |  +---------------------------------------+  |  |
|  |  |      Jenkins CI/CD EC2 Instance     |  |   |  |     Application & Monitoring Server   |  |  |
|  |  |  - Jenkins 2.504 (Port 8080)        |  |   |  |  - SecDO App Stack (PHP 8.3 Apache)  |  |  |
|  |  |  - SonarQube SAST (Port 9000)       |  |   |  |  - MariaDB 11 Database Engine        |  |  |
|  |  |  - Java 21, AWS CLI v2, Trivy     |  |   |  |  - Docker Swarm Cluster Node        |  |  |
|  |  |  - IAM Instance Profile Attached    |  |   |  |  - Prometheus (9090) / Grafana (3000)|  |  |
|  |  +-------------------------------------+  |   |  |  - cAdvisor (8081) / Node Exporter  |  |  |
|  |                                           |   |  +---------------------------------------+  |  |
|  +-------------------------------------------+   +---------------------------------------------+  |
|                        |                                                |                         |
|                        +-----------------------+------------------------+                         |
|                                                |                                                  |
|                        +-----------------------v------------------------+                         |
|                        |     AWS Application Load Balancer (ALB)        |                         |
|                        |   secdo-alb-124066993.ap-south-1.elb.amazonaws.com|                         |
|                        +------------------------------------------------+                         |
+---------------------------------------------------------------------------------------------------+
```

---

## 🚀 Key Pipelines Overview

### 1. Main DevSecOps CI/CD Pipeline (`jenkins/Jenkinsfile`)
Executes 12 automated stages upon GitHub Push webhooks:
1. **Checkout Source Code**: Clones Git repository and extracts commit SHA.
2. **Build & Code Syntax Validation**: Validates PHP syntax (`php -l`).
3. **SonarQube SAST Scan**: Executes static security scanning.
4. **SonarQube Quality Gate Check**: Evaluates security quality gate thresholds.
5. **Trivy Filesystem Scan**: Audits filesystem dependencies for vulnerabilities.
6. **Docker Multi-Stage Build**: Containerizes application using PHP 8.3 Apache.
7. **Trivy Container Image Scan**: Scans container layers for HIGH/CRITICAL CVEs.
8. **AWS ECR Keyless Login & Push**: Authenticates via IAM Instance Profile STS tokens and pushes `latest` and `${BUILD_NUMBER}` tags.
9. **Docker Swarm Cluster Deployment**: Deploys application stack to production Application server.
10. **Application Health Check Probe**: Polls `/health.php` endpoint up to 15 times until HTTP 200 OK.
11. **OWASP ZAP DAST Scan**: Executes dynamic containerized baseline security testing.
12. **Consolidate Security Reports**: Archives artifacts and sends HTML summary emails with 4 attached report files to all 4 team members.

### 2. Deep AWS Infrastructure Compliance Audit Pipeline (`jenkins/Jenkinsfile-ca`)
Executes 8 automated cloud posture & IaC security audit stages:
1. **Checkout Repository**: Pulls latest Terraform IaC code.
2. **Gitleaks Secret Audit**: Scans commit history for hardcoded AWS keys or passwords.
3. **Terraform Format & Syntax Audit**: Runs `hashicorp/terraform` container validation.
4. **Checkov CIS Benchmarks & PCI-DSS Audit**: Audits IaC against CIS AWS Benchmarks v3.0, PCI-DSS, and HIPAA.
5. **tfsec AWS Misconfiguration Audit**: Scans for unencrypted storage or open security groups.
6. **Prowler v4 Deep AWS Live Security Audit**: Executes Prowler v4 containerized live cloud audit against AWS Account `325698037625`.
7. **Live AWS Security Groups, IAM Roles & Policy Audit**: Audits live security group ports, IAM roles, and customer policies.
8. **Consolidate Compliance Executive Report**: Sends HTML compliance summary emails with 6 attached report files to all 4 team members.

---

## 📧 Team Email Routing Configuration

- **Sender**: `patilrahulprafulla@gmail.com`
- **Recipient List**:
  1. `patilrahulprafulla1@gmail.com`
  2. `dangerushi19@gmail.com`
  3. `ameybhalerao004@gmail.com`
  4. `ashutoshkabade1961@gmail.com`

---

## 🛠️ Infrastructure Setup & Execution Commands

### 1. Provision AWS Infrastructure via Terraform
```bash
cd SecDO/terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### 2. Deploy Application Stack via Docker Swarm
```bash
cd SecDO/deployment
docker swarm init
docker stack deploy -c docker-swarm.yml secdo_app
```

### 3. Deploy Observability Stack (Prometheus + Grafana + cAdvisor)
```bash
cd SecDO/scripts
./setup-app-server.sh
```

---

## 📜 License
Developed for enterprise CDAC / DevSecOps engineering portfolio demonstrations.
