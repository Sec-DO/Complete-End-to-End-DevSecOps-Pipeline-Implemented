#!/bin/bash
# SecDO - Bastion Host Setup Script
# Installs AWS CLI v2, SSH Agent Forwarding, and Node Exporter Telemetry Agent (Port 9100)

set -e

echo "================================================="
echo "Starting Bastion Host Setup & Telemetry Agent..."
echo "================================================="

sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release unzip git net-tools htop jq openssh-client

# Install AWS CLI v2
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Configure Passwordless SSH config on Bastion Host for all VPC Private Subnet IPs
mkdir -p "$HOME/.ssh"
cat << 'EOF' > "$HOME/.ssh/config"
Host 10.0.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ForwardAgent yes
EOF
chmod 600 "$HOME/.ssh/config"

# Generate SSH key pair for Bastion if missing
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -b 2048 -f "$HOME/.ssh/id_rsa" -N ""
fi

# Deploy Node Exporter Container for Bastion EC2 Server Metrics (Port 9100)
echo "Deploying Node Exporter Telemetry Agent on Bastion Host..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu || true
sudo systemctl enable --now docker

if ! sudo docker ps -a | grep -q bastion-node-exporter; then
    sudo docker run -d --name bastion-node-exporter \
        --restart unless-stopped \
        -p 9100:9100 \
        -v /proc:/host/proc:ro \
        -v /sys:/host/sys:ro \
        -v /:/rootfs:ro \
        prom/node-exporter:v1.7.0 \
        --path.procfs=/host/proc \
        --path.sysfs=/host/sys
fi

echo "================================================="
echo "Bastion Host Setup Complete!"
echo "Node Exporter Telemetry Active on Port 9100."
echo "================================================="
