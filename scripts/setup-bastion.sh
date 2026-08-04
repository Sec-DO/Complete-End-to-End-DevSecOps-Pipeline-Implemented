#!/bin/bash
# SecDO - Bastion Host Setup Script
# Operating System: Ubuntu 24.04 / 22.04 LTS

set -e

echo "================================================="
echo "Starting Bastion Host Setup..."
echo "================================================="

sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release unzip git net-tools htop jq

# Install AWS CLI v2
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

echo "================================================="
echo "Bastion Host Setup Complete!"
echo "AWS CLI Version: $(aws --version)"
echo "================================================="
