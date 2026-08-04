#!/bin/bash
# SecDO - Jenkins & SonarQube Server Complete Installation Script
# Configured with Node Exporter (9100) & cAdvisor (8081) for Complete Container Telemetry

set -e

echo "================================================="
echo "Starting Jenkins & SonarQube Setup..."
echo "================================================="

# 1. Configure 2GB Swap Memory
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# 2. Install Prerequisites & Java 17
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release openjdk-17-jre unzip git net-tools htop jq openssh-client

# 3. Install AWS CLI v2
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# 4. Install Docker Engine
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker ubuntu || true
sudo systemctl enable --now docker

# 5. Install Jenkins LTS
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins
sudo usermod -aG docker jenkins || true
sudo systemctl restart jenkins

# 6. Passwordless SSH Key Setup
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -b 2048 -f "$HOME/.ssh/id_rsa" -N ""
fi
cat << 'EOF' > "$HOME/.ssh/config"
Host 10.0.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentityFile ~/.ssh/id_rsa
EOF
chmod 600 "$HOME/.ssh/config"

sudo mkdir -p /var/lib/jenkins/.ssh
if [ ! -f "/var/lib/jenkins/.ssh/id_rsa" ]; then
    sudo ssh-keygen -t rsa -b 2048 -f "/var/lib/jenkins/.ssh/id_rsa" -N ""
fi
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh

# 7. Install Trivy Vulnerability Scanner
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install -y trivy

# 8. Deploy Node Exporter Container (Port 9100)
if ! sudo docker ps -a | grep -q jenkins-node-exporter; then
    sudo docker run -d --name jenkins-node-exporter \
        --restart unless-stopped \
        -p 9100:9100 \
        -v /proc:/host/proc:ro \
        -v /sys:/host/sys:ro \
        -v /:/rootfs:ro \
        prom/node-exporter:v1.7.0 \
        --path.procfs=/host/proc \
        --path.sysfs=/host/sys
fi

# 9. Deploy cAdvisor Container Telemetry Agent (Port 8081)
if ! sudo docker ps -a | grep -q jenkins-cadvisor; then
    sudo docker run -d --name jenkins-cadvisor \
        --restart unless-stopped \
        --privileged \
        -p 8081:8080 \
        -v /:/rootfs:ro \
        -v /var/run:/var/run:ro \
        -v /sys:/sys:ro \
        -v /var/lib/docker/:/var/lib/docker:ro \
        gcr.io/cadvisor/cadvisor:v0.47.2
fi

# 10. Deploy SonarQube Server Container (Port 9000)
sudo sysctl -w vm.max_map_count=512000
echo "vm.max_map_count=512000" | sudo tee -a /etc/sysctl.conf

if ! sudo docker ps -a | grep -q sonarqube; then
    sudo docker run -d --name sonarqube \
        --restart always \
        -p 9000:9000 \
        -v sonarqube_data:/opt/sonarqube/data \
        -v sonarqube_extensions:/opt/sonarqube/extensions \
        -v sonarqube_logs:/opt/sonarqube/logs \
        sonarqube:community
fi

echo "================================================="
echo "Jenkins, Node Exporter, & cAdvisor Setup Complete!"
echo "================================================="
