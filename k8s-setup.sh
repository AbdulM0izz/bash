#!/bin/bash
# complete-k8s-setup.sh - Run this on ALL nodes (master, slave1, slave2)
# Kubernetes v1.28 (stable version) - Complete Setup Script

set -e

echo "================================================"
echo "Kubernetes Complete Setup Script - v1.28"
echo "Run this on ALL nodes: master, slave1, slave2"
echo "================================================"
echo ""

# Update system
echo "[1/9] Updating system packages..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Disable swap
echo ""
echo "[2/9] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "✓ Swap disabled"

# Load kernel modules
echo ""
echo "[3/9] Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
echo "✓ Kernel modules loaded"

# Set sysctl parameters
echo ""
echo "[4/9] Setting sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system >/dev/null 2>&1
echo "✓ Sysctl parameters configured"

# Install containerd
echo ""
echo "[5/9] Installing containerd..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

# Install containerd - handle existing installation
if dpkg -l | grep -q containerd.io; then
    echo "Containerd already installed, upgrading..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confnew" containerd.io
else
    sudo apt-get install -y containerd.io
fi
echo "✓ Containerd installed"

# Configure containerd
echo ""
echo "[6/9] Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

# Enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd >/dev/null 2>&1
echo "✓ Containerd configured and started"

# Install Kubernetes components
echo ""
echo "[7/9] Installing Kubernetes components (kubeadm, kubelet, kubectl)..."
sudo apt-get install -y apt-transport-https ca-certificates curl

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null

# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y

# Unhold packages if they are held
sudo apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true

# Install Kubernetes packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kubelet kubeadm kubectl --allow-change-held-packages

# Hold packages to prevent automatic updates
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable kubelet >/dev/null 2>&1
echo "✓ Kubernetes components installed"

# Install additional utilities
echo ""
echo "[8/9] Installing additional utilities..."
sudo apt-get install -y bash-completion
echo "✓ Utilities installed"

# Verify installation
echo ""
echo "[9/9] Verifying installation..."
echo "Kubeadm version: $(kubeadm version -o short)"
echo "Kubelet version: $(kubelet --version | awk '{print $2}')"
echo "Kubectl version: $(kubectl version --client -o yaml | grep gitVersion | awk '{print $2}')"

echo ""
echo "================================================"
echo "✓ Setup completed successfully!"
echo "================================================"
echo ""
echo "System Information:"
echo "-------------------"
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo ""
echo "Installed Components:"
echo "---------------------"
echo "- Containerd: $(containerd --version | awk '{print $3}')"
echo "- Kubeadm: $(kubeadm version -o short)"
echo "- Kubelet: $(kubelet --version | awk '{print $2}')"
echo "- Kubectl: $(kubectl version --client -o yaml | grep gitVersion | awk '{print $2}')"
echo ""
echo "================================================"
echo "Next Steps:"
echo "================================================"
echo ""
echo "1. Agar ye MASTER node hai:"
echo "   → Master initialization script run karein"
echo ""
echo "2. Agar ye SLAVE/WORKER node hai:"
echo "   → Master se JOIN command copy karein aur yahan run karein"
echo ""
echo "3. Sabhi nodes pe ye script successfully run karne ke baad:"
echo "   → Master pe initialization karein"
echo "   → Workers ko join karein"
echo ""
echo "================================================"
echo "Important Commands:"
echo "================================================"
echo ""
echo "Status check karein:"
echo "  sudo systemctl status containerd"
echo "  sudo systemctl status kubelet"
echo ""
echo "Logs dekhein:"
echo "  sudo journalctl -u kubelet -f"
echo "  sudo journalctl -u containerd -f"
echo ""
echo "================================================"