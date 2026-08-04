#!/bin/bash
# SecDO - Automated Infrastructure Teardown Script (Destroy Infra)
# Teardown all AWS resources created by Terraform to prevent cloud charges.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "================================================="
echo "WARNING: SecDO Infrastructure Teardown Initiated"
echo "Region: ap-south-1 (Mumbai)"
echo "================================================="

if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "ERROR: Terraform directory not found at $TERRAFORM_DIR"
    exit 1
fi

read -p "Are you sure you want to DESTROY all SecDO AWS Infrastructure? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Teardown cancelled by user."
    exit 0
fi

cd "$TERRAFORM_DIR"

# 1. Clean ECR Images to allow smooth ECR repo deletion
echo "[1/2] Attempting to purge ECR container images..."
ECR_NAME=$(terraform output -raw ecr_repository_url 2>/dev/null | cut -d'/' -f2 || echo "secdo-ecr")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "ap-south-1")

if command -v aws &> /dev/null && [ -n "$ECR_NAME" ]; then
    aws ecr batch-delete-image \
        --repository-name "$ECR_NAME" \
        --region "$AWS_REGION" \
        --image-ids "$(aws ecr list-images --repository-name "$ECR_NAME" --region "$AWS_REGION" --query 'imageIds[*]' --output json 2>/dev/null)" 2>/dev/null || true
fi

# 2. Destroy Terraform Managed Resources
echo "[2/2] Destroying AWS Infrastructure..."
terraform destroy -auto-approve

echo "================================================="
echo "SUCCESS: All SecDO AWS Infrastructure Destroyed!"
echo "================================================="
