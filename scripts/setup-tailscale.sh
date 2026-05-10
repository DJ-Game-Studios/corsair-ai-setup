#!/bin/bash

# Tailscale Setup Script for Corsair AI Workstation
# Join the fleet mesh network for secure remote access

set -e

echo "=========================================="
echo "Tailscale Setup Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root. Use sudo for specific commands."
    exit 1
fi

# Step 1: Add Tailscale repository
echo "Step 1: Adding Tailscale repository..."
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt update
echo ""

# Step 2: Install Tailscale
echo "Step 2: Installing Tailscale..."
sudo apt install -y tailscale
echo ""

# Step 3: Authenticate with Tailscale
echo "Step 3: Authenticating with Tailscale..."
echo "This will open a browser window for authentication."
echo "If no browser is available, a URL will be provided."
echo ""
read -p "Press Enter to continue..."
sudo tailscale up --ssh=server --hostname=dj-linux-gpu-node-6
echo ""

# Step 4: Configure firewall
echo "Step 4: Configuring firewall for Tailscale..."
sudo ufw allow 41694/udp comment 'Tailscale DERP'
sudo ufw allow from 100.64.0.0/10 comment 'Tailscale CGNAT'
echo ""

# Step 5: Verify installation
echo "Step 5: Verifying Tailscale installation..."
if command -v tailscale &> /dev/null; then
    echo "Tailscale installed successfully"
else
    echo "Error: Tailscale not found"
    exit 1
fi

if systemctl is-active --quiet tailscaled; then
    echo "Tailscale service is running"
else
    echo "Warning: Tailscale service is not running"
    exit 1
fi

echo ""
echo "=========================================="
echo "Tailscale Setup Complete!"
echo "=========================================="
echo ""

# Show Tailscale status
echo "Tailscale Status:"
sudo tailscale status --self
echo ""

echo "Tailscale IP:"
ip addr show tailscale0 | grep "inet " | awk '{print $2}' | cut -d/ -f1
echo ""

echo "IMPORTANT NEXT STEPS:"
echo "1. Verify connectivity to fleet nodes:"
echo "   ping main-pc"
echo "   ping mac-pro"
echo "2. Configure ACL rules in Tailscale admin console"
echo "3. Test SSH access: ssh dj-linux-gpu-node-6"
echo "4. Run network tests: ./tests/test-network.sh"
echo ""
