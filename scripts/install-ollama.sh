#!/bin/bash

# Ollama Installation Script for Corsair AI Workstation
# AMD Ryzen AI Max+ 395 with ROCm GPU acceleration

set -e

echo "=========================================="
echo "Ollama Installation Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root. Use sudo for specific commands."
    exit 1
fi

# Check if ROCm is installed
if [ ! -f /opt/rocm/bin/rocm-smi ]; then
    echo "Error: ROCm not found. Please install ROCm first: ./scripts/install-rocm.sh"
    exit 1
fi

# Step 1: Mount external storage
echo "Step 1: Mounting external storage..."
if [ ! -d /run/media/dj/SEA-ARC-6TB ]; then
    echo "Creating mount point..."
    sudo mkdir -p /run/media/dj/SEA-ARC-6TB
fi

# Try to detect the external drive
EXTERNAL_DRIVE=$(lsblk -o NAME,MOUNTPOINT -l | grep -v "^$" | grep -v "SWAP" | tail -n 1 | awk '{print "/dev/"$1}')

if [ -n "$EXTERNAL_DRIVE" ]; then
    echo "Detected external drive: $EXTERNAL_DRIVE"
    read -p "Mount $EXTERNAL_DRIVE to /run/media/dj/SEA-ARC-6TB? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo mount $EXTERNAL_DRIVE /run/media/dj/SEA-ARC-6TB
    else
        echo "Skipping mount. Please mount manually."
    fi
else
    echo "Could not detect external drive automatically."
    echo "Please mount it manually to /run/media/dj/SEA-ARC-6TB"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create ai-models directory
sudo mkdir -p /run/media/dj/SEA-ARC-6TB/ai-models
sudo chown -R $USER:$USER /run/media/dj/SEA-ARC-6TB/ai-models
echo "Created /run/media/dj/SEA-ARC-6TB/ai-models"
echo ""

# Step 2: Set environment variables
echo "Step 2: Setting Ollama environment variables..."
if ! grep -q "OLLAMA_MODELS" ~/.bashrc; then
    echo 'export OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models' >> ~/.bashrc
    echo 'export OLLAMA_GPU=rocm' >> ~/.bashrc
    echo "Added Ollama environment variables to ~/.bashrc"
else
    echo "Ollama environment variables already in ~/.bashrc"
fi

# Set them for current session
export OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models
export OLLAMA_GPU=rocm
echo ""

# Step 3: Install Ollama
echo "Step 3: Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
echo ""

# Step 4: Configure systemd service
echo "Step 4: Configuring Ollama systemd service..."
sudo mkdir -p /etc/systemd/system/ollama.service.d

sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models"
Environment="OLLAMA_GPU=rocm"
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_NUM_GPU=99"
Environment="OLLAMA_CTX_SIZE=8192"
Environment="OLLAMA_BATCH_SIZE=512"
EOF

echo "Created systemd override with custom configuration"
echo ""

# Step 5: Reload and start service
echo "Step 5: Starting Ollama service..."
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl start ollama
echo ""

# Step 6: Wait for service to start
echo "Waiting for Ollama service to start..."
sleep 5

# Step 7: Verify installation
echo "Step 7: Verifying Ollama installation..."
if command -v ollama &> /dev/null; then
    echo "Ollama version: $(ollama --version)"
else
    echo "Error: Ollama not found in PATH"
    exit 1
fi

if systemctl is-active --quiet ollama; then
    echo "Ollama service is running"
else
    echo "Warning: Ollama service is not running"
    echo "Check status with: sudo systemctl status ollama"
fi

echo ""
echo "=========================================="
echo "Ollama Installation Complete!"
echo "=========================================="
echo ""
echo "IMPORTANT NEXT STEPS:"
echo "1. Reload your shell configuration: source ~/.bashrc"
echo "2. Download your first model: ollama pull qwen2.5:14b"
echo "3. Test Ollama: ollama run qwen2.5:14b 'Hello!'"
echo "4. Run the Ollama test: ./tests/test-ollama.sh"
echo "5. Download more models: ./scripts/download-models.sh"
echo ""
echo "Model storage: $OLLAMA_MODELS"
echo "GPU acceleration: $OLLAMA_GPU"
echo ""
