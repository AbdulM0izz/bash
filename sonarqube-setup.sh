#!/bin/bash

# SonarQube Docker Setup Script for EC2
# Port 9000:9000 with LTS version

echo "=========================================="
echo "Docker & SonarQube Installation Script"
echo "=========================================="

# System update
echo "Step 1: System update kar rahe hain..."
sudo apt update -y

# Docker dependencies install
echo "Step 2: Docker dependencies install kar rahe hain..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Docker GPG key add karna
echo "Step 3: Docker repository setup kar rahe hain..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Docker repository add karna
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker install karna
echo "Step 4: Docker install kar rahe hain..."
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Docker service start karna
echo "Step 5: Docker service start kar rahe hain..."
sudo systemctl start docker
sudo systemctl enable docker

# Current user ko docker group mein add karna
echo "Step 6: User ko docker group mein add kar rahe hain..."
sudo usermod -aG docker $USER

# Docker version check
echo "Step 7: Docker version check..."
docker --version

# System parameters set karna (SonarQube ke liye zaruri)
echo "Step 8: System parameters configure kar rahe hain..."
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072

# Permanent changes ke liye
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf

# Ulimit settings
echo "sonarqube   -   nofile   131072" | sudo tee -a /etc/security/limits.conf
echo "sonarqube   -   nproc    8192" | sudo tee -a /etc/security/limits.conf

# SonarQube LTS container run karna
echo "Step 9: SonarQube LTS container run kar rahe hain..."
sudo docker run -d \
    --name sonarqube \
    -p 9000:9000 \
    --restart=always \
    -v sonarqube_data:/opt/sonarqube/data \
    -v sonarqube_extensions:/opt/sonarqube/extensions \
    -v sonarqube_logs:/opt/sonarqube/logs \
    sonarqube:lts-community

# Container status check
echo "Step 10: Container status check kar rahe hain..."
sleep 5
sudo docker ps | grep sonarqube

# Logs display
echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "SonarQube access karne ke liye:"
echo "URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000"
echo ""
echo "Default Login Credentials:"
echo "Username: admin"
echo "Password: admin"
echo "(First login pe password change karna hoga)"
echo ""
echo "Container logs dekhne ke liye:"
echo "sudo docker logs -f sonarqube"
echo ""
echo "Container status check:"
echo "sudo docker ps"
echo ""
echo "=========================================="
echo "Important Notes:"
echo "1. EC2 Security Group mein port 9000 open karna na bhoolein"
echo "2. SonarQube start hone mein 2-3 minute lag sakte hain"
echo "3. Logout aur login karein docker commands bina sudo ke chalane ke liye"
echo "=========================================="
echo ""
echo "Container start ho raha hai, logs check kar rahe hain..."
echo "Ctrl+C press karke exit kar sakte hain"
echo ""
sudo docker logs -f sonarqube