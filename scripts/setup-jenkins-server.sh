#!/bin/bash
# SecDO - Complete Automated Jenkins, Java 21, Docker, SonarScanner & SonarQube Installer
# Operating System: Ubuntu 24.04 / 22.04 LTS

set -e

echo "======================================"
echo " Updating System Packages"
echo "======================================"
sudo apt update -y

echo "======================================"
echo " Installing Required Utilities & PHP CLI"
echo "======================================"
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release unzip git maven net-tools htop jq php-cli

echo "======================================"
echo " Installing Java 21"
echo "======================================"
sudo apt install -y openjdk-21-jdk
java -version

echo "======================================"
echo " Adding Jenkins Repository & GPG Key"
echo "======================================"
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/jenkins.gpg > /dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/jenkins.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y

echo "======================================"
echo " Installing Jenkins"
echo "======================================"
sudo apt install -y jenkins

echo "======================================"
echo " Starting & Enabling Jenkins Service"
echo "======================================"
sudo systemctl daemon-reload
sudo systemctl enable --now jenkins

echo "======================================"
echo " Installing Docker Engine"
echo "======================================"
sudo apt install -y docker.io
sudo systemctl enable --now docker

sudo usermod -aG docker ubuntu 2>/dev/null || true
sudo usermod -aG docker jenkins 2>/dev/null || true
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

echo "======================================"
echo " Installing SonarScanner CLI"
echo "======================================"
if [ ! -f /usr/local/bin/sonar-scanner ]; then
    wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
    unzip -q sonar-scanner-cli-5.0.1.3006-linux.zip
    sudo mv sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner
    sudo ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
    rm -f sonar-scanner-cli-5.0.1.3006-linux.zip
fi

echo "======================================"
echo " Installing Aqua Trivy Scanner"
echo "======================================"
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update -y && sudo apt install -y trivy

echo "======================================"
echo " Deploying SonarQube Container (9000)"
echo "======================================"
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

echo "======================================"
echo " Jenkins Initial Password"
echo "======================================"
sleep 5
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo ""
echo "======================================"
echo " Installation Completed Successfully!"
echo "======================================"
