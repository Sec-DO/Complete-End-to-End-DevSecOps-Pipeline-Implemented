#!/bin/bash
# SecDO - Jenkins & SonarQube Server Complete Installation Script
# Operating System: Ubuntu 24.04 / 22.04 LTS

set -e

echo "================================================="
echo "Starting Jenkins & SonarQube Server Setup..."
echo "================================================="

# 1. Update Package Repositories & Install Prerequisites
echo "[1/6] Installing Essential Utilities & Java 17..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release openjdk-17-jre unzip git net-tools htop jq

# 2. Install AWS CLI v2
echo "[2/6] Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi
echo "AWS CLI Version: $(aws --version)"

# 3. Install Docker Engine & Compose Plugin
echo "[3/6] Installing Docker Engine..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker ubuntu || true
sudo systemctl enable --now docker

# 4. Install Jenkins LTS
echo "[4/6] Installing Jenkins Long Term Support (LTS)..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

sudo usermod -aG docker jenkins || true
sudo systemctl restart jenkins

# 5. Install Trivy Vulnerability Scanner
echo "[5/6] Installing Aqua Security Trivy Scanner..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update -y
sudo apt-get install -y trivy
echo "Trivy Version: $(trivy --version | head -n 1)"

# 6. Deploy SonarQube Server as Hardened Docker Container (Port 9000)
echo "[6/6] Launching SonarQube Community Edition on Port 9000..."
# Adjust virtual memory limits required by Elasticsearch in SonarQube
sudo sysctl -w vm.max_map_count=512000
echo "vm.max_map_count=512000" | sudo tee -a /etc/sysctl.conf

if ! docker ps -a | grep -q sonarqube; then
    docker run -d --name sonarqube \
        --restart always \
        -p 9000:9000 \
        -v sonarqube_data:/opt/sonarqube/data \
        -v sonarqube_extensions:/opt/sonarqube/extensions \
        -v sonarqube_logs:/opt/sonarqube/logs \
        sonarqube:community
fi

echo "================================================="
echo "Jenkins & SonarQube Setup Completed Successfully!"
echo "Jenkins URL: http://<ALB_OR_PRIVATE_IP>:8080"
echo "SonarQube URL: http://<ALB_OR_PRIVATE_IP>:9000"
echo "Initial Jenkins Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || echo "Password not ready yet."
echo "================================================="
