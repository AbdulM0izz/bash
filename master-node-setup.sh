#!/bin/bash
# master-init.sh - Run this ONLY on the MASTER node
# Kubernetes Master Initialization Script

set -e

echo "================================================"
echo "Kubernetes Master Node Initialization"
echo "⚠️  Sirf MASTER node pe chalayein!"
echo "================================================"
echo ""

# Check if already initialized
if [ -f /etc/kubernetes/admin.conf ]; then
    echo "⚠️  Warning: Cluster already initialized!"
    echo ""
    read -p "Kya aap cluster reset karke new initialization karna chahte hain? (y/n): " reset_confirm
    
    if [[ $reset_confirm == "y" || $reset_confirm == "Y" ]]; then
        echo "Resetting existing cluster..."
        sudo kubeadm reset -f
        sudo rm -rf ~/.kube
        sudo rm -rf /etc/cni/net.d
        sudo systemctl restart containerd
        echo "✓ Cluster reset complete"
    else
        echo "Existing cluster ko use kar rahe hain..."
        
        # Show existing join command
        echo ""
        echo "================================================"
        echo "WORKER NODES KE LIYE JOIN COMMAND:"
        echo "================================================"
        sudo kubeadm token create --print-join-command
        echo "================================================"
        exit 0
    fi
fi

# Get the private IP of this instance
MASTER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "Detected Master Node IP: $MASTER_IP"
echo ""
read -p "Kya ye IP address sahi hai? (y/n): " confirm

if [[ $confirm != "y" && $confirm != "Y" ]]; then
    read -p "Sahi master node IP enter karein: " MASTER_IP
fi

echo ""
echo "================================================"
echo "Initialization shuru ho rahi hai..."
echo "⏰ Ye process 3-5 minutes le sakta hai"
echo "================================================"
echo ""

# Pull required images first
echo "[1/5] Required images download ho rahi hain..."
sudo kubeadm config images pull --cri-socket unix:///var/run/containerd/containerd.sock

# Initialize the cluster
echo ""
echo "[2/5] Kubernetes cluster initialize ho raha hai..."
sudo kubeadm init \
  --apiserver-advertise-address=$MASTER_IP \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket unix:///var/run/containerd/containerd.sock \
  --ignore-preflight-errors=NumCPU

# Set up kubectl for the current user
echo ""
echo "[3/5] kubectl configuration setup ho raha hai..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Wait for API server to be ready
echo ""
echo "Waiting for API server to be ready..."
sleep 10

# Install Flannel CNI
echo ""
echo "[4/5] Flannel network plugin install ho raha hai..."
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Enable kubectl autocompletion
echo ""
echo "[5/5] kubectl autocompletion enable ho raha hai..."
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# Wait for master node to be ready
echo ""
echo "Master node ready hone ka wait kar rahe hain..."
sleep 15

echo ""
echo "================================================"
echo "✓✓✓ Master Node Successfully Initialized! ✓✓✓"
echo "================================================"
echo ""

# Display cluster info
echo "Cluster Information:"
echo "--------------------"
kubectl cluster-info
echo ""

# Display nodes
echo "Current Nodes:"
echo "--------------"
kubectl get nodes -o wide
echo ""

# Display system pods
echo "System Pods Status:"
echo "-------------------"
kubectl get pods -n kube-system
echo ""

# Generate and display join command
echo "================================================"
echo "🔥 WORKER NODES KE LIYE JOIN COMMAND 🔥"
echo "================================================"
echo ""
echo "Ye command COPY karein aur Slave-1 & Slave-2 pe run karein:"
echo ""

JOIN_CMD=$(sudo kubeadm token create --print-join-command)
echo "$JOIN_CMD"

# Save join command to files
echo "$JOIN_CMD" > ~/join-command.txt
echo "#!/bin/bash" > ~/join-command.sh
echo "$JOIN_CMD" >> ~/join-command.sh
chmod +x ~/join-command.sh

echo ""
echo "================================================"
echo "✅ Join command save ho gaya hai:"
echo "   📄 ~/join-command.txt"
echo "   📄 ~/join-command.sh"
echo "================================================"
echo ""

echo "Next Steps:"
echo "----------"
echo "1. Upar diya JOIN command copy karein"
echo "2. Slave-1 pe SSH karein aur command run karein"
echo "3. Slave-2 pe SSH karein aur command run karein"
echo "4. Verification: kubectl get nodes"
echo ""
echo "Useful Commands:"
echo "----------------"
echo "• Nodes check: kubectl get nodes"
echo "• Pods check: kubectl get pods --all-namespaces"
echo "• Join command dubara dekhen: cat ~/join-command.txt"
echo "• New join command: sudo kubeadm token create --print-join-command"
echo ""
echo "================================================"
echo "🎉 Setup Complete! Happy Kuberneting! 🎉"
echo "================================================"