# SecDO – Complete A-to-Z Deployment & Configuration Guide 📖

This document provides complete, exhaustive, step-by-step instructions to build, configure, deploy, monitor, and audit the **SecDO DevSecOps Platform** from scratch (From A to Z).

---

## 📋 Table of Contents
1. [Phase A: AWS Account & IAM Role Setup](#phase-a-aws-account--iam-role-setup)
2. [Phase B: Infrastructure Provisioning via Terraform](#phase-b-infrastructure-provisioning-via-terraform)
3. [Phase C: Jenkins & SonarQube CI/CD Server Configuration](#phase-c-jenkins--sonarqube-cicd-server-configuration)
4. [Phase D: Application Server & Database Cluster Setup](#phase-d-application-server--database-cluster-setup)
5. [Phase E: Observability Stack (Prometheus + Grafana + cAdvisor)](#phase-e-observability-stack-prometheus--grafana--cadvisor)
6. [Phase F: Jenkins Pipeline Job Configuration](#phase-f-jenkins-pipeline-job-configuration)
7. [Phase G: Extended Email Notification Setup](#phase-g-extended-email-notification-setup)
8. [Phase H: Running Pipelines & Verification Guide](#phase-h-running-pipelines--verification-guide)
9. [Phase I: Troubleshooting & Maintenance Matrix](#phase-i-troubleshooting--maintenance-matrix)

---

## Phase A: AWS Account & IAM Role Setup

1. Log into your **AWS Management Console** (`ap-south-1` Mumbai region).
2. Go to **IAM** ➔ **Roles** ➔ Click **Create Role**.
3. Select **AWS Service** ➔ **EC2**.
4. Attach the following managed policies:
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
5. Name the role: **`Jenkins-ECR-EC2-Role`**.
6. Create an Instance Profile named **`jenkins_instance_profile`** linked to this role.

---

## Phase B: Infrastructure Provisioning via Terraform

1. Open Git Bash or terminal on your management workstation.
2. Clone the repository:
   ```bash
   git clone https://github.com/Sec-DO/Complete-End-to-End-DevSecOps-Pipeline-Implemented.git
   cd Complete-End-to-End-DevSecOps-Pipeline-Implemented/terraform
   ```
3. Initialize and apply Terraform IaC templates:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```
4. Terraform will output:
   - `jenkins_public_ip`: `10.0.10.17` (Internal) / Public ALB Route
   - `app_server_public_ip`: `10.0.20.60` (Internal) / Public ALB Route
   - `alb_dns_name`: `secdo-alb-124066993.ap-south-1.elb.amazonaws.com`

---

## Phase C: Jenkins & SonarQube CI/CD Server Configuration

1. SSH into the Jenkins EC2 Server:
   ```bash
   ssh -i ~/.ssh/SecDO.pem ubuntu@<JENKINS_SERVER_IP>
   ```
2. Run the automated Jenkins setup script:
   ```bash
   cd ~/SecDO/scripts
   chmod +x setup-jenkins-server.sh
   ./setup-jenkins-server.sh
   ```
   This script installs:
   - OpenJDK 21
   - Jenkins `v2.504.1`
   - Docker Engine & Compose Plugin
   - AWS CLI v2
   - Aqua Trivy Vulnerability Scanner
   - SonarQube Scanner `v5.0.1`

3. Start SonarQube container on Port `9000`:
   ```bash
   docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
   ```
4. Open SonarQube in browser: **`http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:9000`**
   - Default Login: `admin` / `admin` (Change to new password upon first login).
   - Go to **Account** ➔ **Security** ➔ **Generate Token** ➔ Name: `jenkins-sonar-token` ➔ Copy the token.

5. Open Jenkins in browser: **`http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:8080`**
   - Retrieve unlock key: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
   - Install Suggested Plugins.
   - Create Admin User: `admin` / `Sunbeam@2002`.

6. Configure SonarQube in Jenkins:
   - Go to **Manage Jenkins** ➔ **Credentials** ➔ **System** ➔ **Global credentials**.
   - Add Credential ➔ Kind: **Secret text** ➔ Secret: *(Paste SonarQube Token)* ➔ ID: `sonar-token`.
   - Go to **Manage Jenkins** ➔ **System** ➔ **SonarQube servers**:
     - Name: `SonarQube`
     - Server URL: `http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:9000`
     - Server authentication token: Select `sonar-token`.

---

## Phase D: Application Server & Database Cluster Setup

1. SSH into the Application EC2 Server:
   ```bash
   ssh -i ~/.ssh/SecDO.pem ubuntu@10.0.20.60
   ```
2. Run the automated Application Host setup script:
   ```bash
   cd ~/SecDO/scripts
   chmod +x setup-app-server.sh
   ./setup-app-server.sh
   ```
   This script configures:
   - 2GB Swap File for Free Tier RAM Optimization.
   - Docker Engine & Compose Plugin.
   - Initializes Docker Swarm Cluster (`docker swarm init`).

3. Start MariaDB 11 Database Engine:
   ```bash
   docker run -d --name secdo-db \
     -e MYSQL_ROOT_PASSWORD=root_pass \
     -e MYSQL_DATABASE=secdo_db \
     -e MYSQL_USER=secdo_user \
     -e MYSQL_PASSWORD=secdo_pass \
     -p 3306:3306 \
     mariadb:11
   ```

---

## Phase E: Observability Stack (Prometheus + Grafana + cAdvisor)

1. Verify Observability Containers on Application Host (`10.0.20.60`):
   ```bash
   cd ~/secdo-monitoring
   docker compose ps
   ```
   Ensures the following 4 containers are `Up`:
   - `secdo-prometheus` (Port `9090`)
   - `secdo-grafana` (Port `3000`)
   - `secdo-node-exporter` (Port `9100`)
   - `secdo-cadvisor` (Port `8081`)

2. Connect Grafana to Prometheus Data Source:
   - Open Grafana: **`http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:3000`** (Login: `admin` / `admin_secdo_monitoring`).
   - Go to **Connections** ➔ **Data Sources** ➔ **Add data source** ➔ Select **Prometheus**.
   - Set Prometheus URL: `http://prometheus:9090`.
   - Click **Save & test** (Green checkmark: *Data source is working*).

3. Import Dashboards:
   - Click **Dashboards** ➔ **New** ➔ **Import**.
   - Type Dashboard ID **`1860`** (Node Exporter Full) ➔ Click **Load** ➔ Select **Prometheus** ➔ Click **Import**.
   - Type Dashboard ID **`14282`** (cAdvisor Container Performance) ➔ Click **Load** ➔ Select **Prometheus** ➔ Click **Import**.

---

## Phase F: Jenkins Pipeline Job Configuration

### 1. Main Application CI/CD Job (`SecDO-Pipeline`)
1. Open Jenkins: **`http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:8080`**
2. Click **New Item** ➔ Name: `SecDO-Pipeline` ➔ Select **Pipeline** ➔ Click **OK**.
3. Check **GitHub hook trigger for GPRT polling**.
4. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/Sec-DO/Complete-End-to-End-DevSecOps-Pipeline-Implemented.git`
   - Branch Specifier: `*/main`
   - Script Path: `jenkins/Jenkinsfile`
5. Click **Save**.

### 2. Deep AWS Compliance Audit Job (`Compliance`)
1. Click **New Item** ➔ Name: `Compliance` ➔ Select **Pipeline** ➔ Click **OK**.
2. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/Sec-DO/Complete-End-to-End-DevSecOps-Pipeline-Implemented.git`
   - Branch Specifier: `*/main`
   - Script Path: `jenkins/Jenkinsfile-ca`
3. Click **Save**.

---

## Phase G: Extended Email Notification Setup

1. Open Jenkins: **`http://secdo-alb-124066993.ap-south-1.elb.amazonaws.com:8080`**
2. Go to **Manage Jenkins** ➔ **System**.
3. Scroll down to **Extended E-mail Notification**:
   - **SMTP server**: `smtp.gmail.com`
   - **SMTP Port**: `465`
   - Check **`Use SSL`**
   - **Credentials**: Add Username (`patilrahulprafulla1@gmail.com`) and Password (`Your-16-Char-App-Password`). Select in dropdown.
   - **Default Content Type**: `HTML (text/html)`
   - **Default Recipients**: `patilrahulprafulla1@gmail.com`
   - Check **`Allow sending to unregistered users`**
4. Scroll to the bottom and click **Save**.

---

## Phase H: Running Pipelines & Verification Guide

1. Push a commit to GitHub:
   ```bash
   git add .
   git commit -m "feat: Trigger end-to-end pipeline build"
   git push origin main
   ```
2. Click **Build Now** in `SecDO-Pipeline`.
   - Verify all 12 stages pass (`✅ Passed`).
   - Check email inbox (`patilrahulprafulla1@gmail.com`) for HTML table and 4 report attachments.
3. Click **Build Now** in `Compliance`.
   - Verify all 8 compliance audit stages pass (`✅ Passed`).
   - Check email inbox for Prowler, Checkov, and tfsec report attachments.

---

## Phase I: Troubleshooting & Maintenance Matrix

| Symptom / Failure | Root Cause | Exact Resolution Command |
| :--- | :--- | :--- |
| **`502 Bad Gateway` on Web App** | Database tables uninitialized | `db.php` has auto-migration built-in. Restart app: `docker stack deploy -c docker-swarm.yml secdo_app` |
| **`Permission denied (publickey)` in SSH** | SSH key missing on Jenkins node | Copy key: `cp ~/.ssh/SecDO.pem /var/lib/jenkins/.ssh/SecDO.pem && chmod 400 /var/lib/jenkins/.ssh/SecDO.pem` |
| **`trivy: not found` in Stage 5/7** | Trivy binary path missing | Install Trivy: `sudo apt-get install -y trivy` or update script path |
| **`Not sent to valid addresses` in Email** | Security realm check blocking emails | Go to **Manage Jenkins ➔ System ➔ Extended E-mail Notification**, check **Allow sending to unregistered users** |
| **Grafana Dashboard shows `No Data`** | Prometheus data source disconnected | Set Prometheus URL to `http://prometheus:9090` in Grafana data source settings |

---

🎉 **Congratulations! Your SecDO DevSecOps & AWS Compliance Platform is 100% Operational!** 🚀
