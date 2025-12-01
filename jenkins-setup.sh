#!/bin/bash

# Jenkins EC2 Setup Script
# Ubuntu/Debian ke liye

echo "=========================================="
echo "Jenkins Installation Script"
echo "=========================================="

# System update (non-interactive mode)
echo "Step 1: System update kar rahe hain..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo apt upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Java installation (Jenkins ke liye zaruri hai)
echo "Step 2: Java install kar rahe hain..."
sudo apt install openjdk-17-jdk -y

# Java version check
echo "Java version:"
java -version

# Jenkins repository add karna
echo "Step 3: Jenkins repository add kar rahe hain..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Jenkins install karna
echo "Step 4: Jenkins install kar rahe hain..."
sudo apt update -y
sudo apt install jenkins -y

# Jenkins service start karna
echo "Step 5: Jenkins service start kar rahe hain..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Jenkins status check
echo "Step 6: Jenkins status check kar rahe hain..."
sudo systemctl status jenkins --no-pager

# Firewall configuration (agar UFW enabled hai)
echo "Step 7: Firewall configure kar rahe hain..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 8080
    sudo ufw allow OpenSSH
    echo "Firewall rules add ho gaye"
fi

# Initial admin password display
echo ""
echo "=========================================="
echo "Jenkins successfully install ho gaya!"
echo "=========================================="
echo ""
echo "Jenkins access karne ke liye:"
echo "URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo ""
echo "Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "=========================================="
echo "Important Notes:"
echo "1. EC2 Security Group mein port 8080 open karna na bhoolein"
echo "2. Browser mein URL open karein aur initial password enter karein"
echo "3. Recommended plugins install karein"
echo "=========================================="