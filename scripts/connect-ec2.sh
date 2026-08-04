#!/bin/bash
# SecDO EC2 SSH Connection Helper (Bastion ProxyJump Support)
# Allows SSH access into Private Subnet EC2 instances via Public Bastion Host using SecDO.pem

KEY_FILE="${1:-SecDO.pem}"
BASTION_IP="${2}"
TARGET_PRIVATE_IP="${3}"

if [ -z "$BASTION_IP" ]; then
    echo "Usage:"
    echo "  1. Direct SSH to Bastion Host:"
    echo "     ./connect-ec2.sh <PATH_TO_SecDO.pem> <BASTION_PUBLIC_IP>"
    echo "  2. Jump SSH into Private Instance:"
    echo "     ./connect-ec2.sh <PATH_TO_SecDO.pem> <BASTION_PUBLIC_IP> <TARGET_PRIVATE_IP>"
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "ERROR: Key file '$KEY_FILE' not found!"
    exit 1
fi

chmod 400 "$KEY_FILE" 2>/dev/null || true

if [ -z "$TARGET_PRIVATE_IP" ]; then
    echo "Connecting to Public Bastion Host ($BASTION_IP)..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"$BASTION_IP"
else
    echo "Connecting to Private Instance ($TARGET_PRIVATE_IP) via Bastion Host ($BASTION_IP)..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no \
        -o ProxyCommand="ssh -i $KEY_FILE -W %h:%p -o StrictHostKeyChecking=no ubuntu@$BASTION_IP" \
        ubuntu@"$TARGET_PRIVATE_IP"
fi
