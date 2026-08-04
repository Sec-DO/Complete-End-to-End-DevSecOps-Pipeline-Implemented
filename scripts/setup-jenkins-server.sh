#!/bin/bash
# SecDO - Jenkins & SonarQube Server Complete Installation Script
# Includes Passwordless SSH key generation for Jenkins -> App Server deployment

set -e

echo "================================================="
echo "Starting Jenkins & SonarQube Server Setup..."
echo "================================================="

# 1. Update Package Repositories & Install Prerequisites
echo "[1/8] Installing Essential Utilities & Java 17..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release openjdk-17-jre unzip git net-tools htop jq openssh-client

# 2. Install AWS CLI v2
echo "[2/8] Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi
echo "AWS CLI Version: $(aws --version)"

# 3. Install Docker Engine & Compose Plugin
echo "[3/8] Installing Docker Engine..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker ubuntu || true
sudo systemctl enable --now docker

# 4. Install Jenkins LTS
echo "[4/8] Installing Jenkins Long Term Support (LTS)..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

sudo usermod -aG docker jenkins || true
sudo systemctl restart jenkins

# 5. Passwordless SSH Key Setup for Jenkins & Ubuntu Users
echo "[5/8] Configuring Passwordless SSH Execution..."
# Generate SSH key pair for ubuntu user if missing
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -b 2048 -f "$HOME/.ssh/id_rsa" -N ""
fi

# Configure SSH config to ignore StrictHostKeyChecking for VPC internal subnet
cat << 'EOF' > "$HOME/.ssh/config"
Host 10.0.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentityFile ~/.ssh/id_rsa
EOF
chmod 600 "$HOME/.ssh/config"

# Generate SSH key pair for jenkins system user
sudo mkdir -p /var/lib/jenkins/.ssh
if [ ! -f "/var/lib/jenkins/.ssh/id_rsa" ]; then
    sudo ssh-keygen -t rsa -b 2048 -f "/var/lib/jenkins/.ssh/id_rsa" -N ""
fi
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh

# 6. Install Trivy Vulnerability Scanner
echo "[6/8] Installing Aqua Security Trivy Scanner..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update -y
sudo apt-get install -y trivy

# 7. Deploy Node Exporter Container for Jenkins Metrics (Port 9100)
echo "[7/8] Deploying Node Exporter Telemetry Agent..."
if ! docker ps -a | grep -q jenkins-node-exporter; then
    docker run -d --name jenkins-node-exporter \
        --restart unless-stopped \
        -p 9100:9100 \
        -v /proc:/host/proc:ro \
        -v /sys:/host/sys:ro \
        -v /:/rootfs:ro \
        prom/node-exporter:v1.7.0 \
        --path.procfs=/host/proc \
        --path.sysfs=/host/sys
fi

# 8. Deploy SonarQube Server as Hardened Docker Container (Port 9000)
echo "[8/8] Launching SonarQube Community Edition on Port 9000..."
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
echo "Jenkins & Passwordless SSH Setup Completed!"
echo "================================================="
