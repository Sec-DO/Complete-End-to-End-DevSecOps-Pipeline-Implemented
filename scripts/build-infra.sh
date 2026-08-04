#!/bin/bash
# SecDO - Automated Infrastructure Provisioning Script (Build Infra)
# Provision AWS VPC, Subnets, ALB, Bastion Host, Jenkins EC2, App EC2, and ECR Repo via Terraform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "================================================="
echo "SecDO Infrastructure Build Execution"
echo "Target Region: ap-south-1 (Mumbai)"
echo "================================================="

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "ERROR: Terraform directory not found at $TERRAFORM_DIR"
    exit 1
fi

cd "$TERRAFORM_DIR"

# 1. Initialize Terraform Providers
echo "[1/4] Initializing Terraform Providers..."
terraform init

# 2. Validate Terraform HCL Code
echo "[2/4] Validating Infrastructure Code..."
terraform validate

# 3. Generate Execution Plan
echo "[3/4] Generating Terraform Plan..."
terraform plan -out=tfplan

# 4. Apply Infrastructure Changes
echo "[4/4] Provisioning AWS Cloud Infrastructure..."
terraform apply -auto-approve tfplan
rm -f tfplan

echo "================================================="
echo "Infrastructure Provisioning Complete!"
echo "================================================="
terraform output
