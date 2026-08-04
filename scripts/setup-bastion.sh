#!/bin/bash
# SecDO - Bastion Host Setup Script
# Includes Passwordless SSH configuration for Jump Host routing into Private Subnets

set -e

echo "================================================="
echo "Starting Bastion Host Setup & Passwordless SSH Config..."
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

echo "================================================="
echo "Bastion Host Setup Complete!"
echo "Passwordless SSH Agent Forwarding Configured for 10.0.* subnets."
echo "================================================="
