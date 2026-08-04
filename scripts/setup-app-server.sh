#!/bin/bash
# SecDO - Application & Observability Server Installation Script
# Operating System: Ubuntu 24.04 / 22.04 LTS

set -e

echo "================================================="
echo "Starting Application & Observability Server Setup..."
echo "================================================="

# 1. Update Package Repositories & Install Prerequisites
echo "[1/4] Installing System Prerequisites..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release unzip git net-tools htop jq

# 2. Install AWS CLI v2
echo "[2/4] Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi
echo "AWS CLI Version: $(aws --version)"

# 3. Install Docker Engine & Compose Plugin
echo "[3/4] Installing Docker Engine & Compose..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker ubuntu || true
sudo systemctl enable --now docker

# 4. Create Deployment & Monitoring Directory Structure
echo "[4/4] Creating Directory Structure & Launching Monitoring Stack..."
mkdir -p "$HOME/secdo-deploy"
mkdir -p "$HOME/secdo-monitoring/prometheus"

# Copy Prometheus configuration
cat << 'EOF' > "$HOME/secdo-monitoring/prometheus/prometheus.yml"
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'secdo_app'
    metrics_path: '/health.php'
    scrape_interval: 10s
    static_configs:
      - targets: ['secdo-app-prod:80']
EOF

# Copy Docker Compose Monitoring Stack
cat << 'EOF' > "$HOME/secdo-monitoring/docker-compose.yml"
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: secdo-prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - secdo-net

  grafana:
    image: grafana/grafana:10.2.2
    container_name: secdo-grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin_secdo_monitoring
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    networks:
      - secdo-net

  node-exporter:
    image: prom/node-exporter:v1.7.0
    container_name: secdo-node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    ports:
      - "9100:9100"
    networks:
      - secdo-net

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.2
    container_name: secdo-cadvisor
    restart: unless-stopped
    privileged: true
    devices:
      - /dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8081:8080"
    networks:
      - secdo-net

networks:
  secdo-net:
    driver: bridge

volumes:
  prometheus_data:
  grafana_data:
EOF

cd "$HOME/secdo-monitoring"
docker compose up -d

echo "================================================="
echo "Application & Observability Host Ready!"
echo "Prometheus Telemetry: http://<ALB_OR_PRIVATE_IP>:9090"
echo "Grafana Dashboard:   http://<ALB_OR_PRIVATE_IP>:3000"
echo "================================================="
