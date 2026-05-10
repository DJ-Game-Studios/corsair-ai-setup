#!/bin/bash

# ROCm Installation Script for Corsair AI Workstation
# AMD Ryzen AI Max+ 395 with Radeon 8060S (RDNA 3.5)

set -e

echo "=========================================="
echo "ROCm Installation Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root. Use sudo for specific commands."
    exit 1
fi

# Check if Ubuntu 26.04
if [ ! -f /etc/os-release ]; then
    echo "Cannot detect OS version. Exiting."
    exit 1
fi

source /etc/os-release
if [ "$ID" != "ubuntu" ] || [ ! "$VERSION_ID" =~ "26.04" ]; then
    echo "Warning: This script is designed for Ubuntu 26.04."
    echo "Current OS: $PRETTY_NAME"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Verify GPU detection
echo "Step 1: Verifying GPU detection..."
if ! lspci | grep -qi vga; then
    echo "Error: No GPU detected. Please check hardware."
    exit 1
fi

GPU_INFO=$(lspci | grep -i vga)
echo "GPU detected: $GPU_INFO"
echo ""

# Step 2: Add AMD ROCm repository
echo "Step 2: Adding AMD ROCm repository..."
wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/6.0/ ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update
echo ""

# Step 3: Install ROCm
echo "Step 3: Installing ROCm packages..."
sudo apt install -y rocm-dev rocm-libs rocm-utils
echo ""

# Step 4: Configure user permissions
echo "Step 4: Configuring user permissions..."
sudo usermod -a -G render,video $USER
echo "Added user $USER to render and video groups."
echo "IMPORTANT: You must log out and log back in for group changes to take effect."
echo ""

# Step 5: Set environment variables
echo "Step 5: Setting environment variables..."
if ! grep -q "rocm/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:/opt/rocm/bin:/opt/rocm/opencl/bin' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib' >> ~/.bashrc
    echo 'export CPATH=$CPATH:/opt/rocm/include' >> ~/.bashrc
    echo "Added ROCm paths to ~/.bashrc"
else
    echo "ROCm paths already in ~/.bashrc"
fi
echo ""

# Step 6: Set performance environment variables
echo "Step 6: Setting performance tuning variables..."
if ! grep -q "HIP_VISIBLE_DEVICES" ~/.bashrc; then
    echo 'export HIP_VISIBLE_DEVICES=0' >> ~/.bashrc
    echo 'export HSA_ENABLE_SDMA=0' >> ~/.bashrc
    echo 'export GPU_MAX_HEAP_SIZE=100' >> ~/.bashrc
    echo 'export GPU_MAX_ALLOC_PERCENT=100' >> ~/.bashrc
    echo 'export GPU_SINGLE_ALLOC_PERCENT=100' >> ~/.bashrc
    echo "Added performance tuning variables to ~/.bashrc"
else
    echo "Performance tuning variables already in ~/.bashrc"
fi
echo ""

# Step 7: Install OpenCL runtime
echo "Step 7: Installing OpenCL runtime..."
sudo apt install -y ocl-icd-opencl-dev
echo ""

# Step 8: Install MIOpen for deep learning
echo "Step 8: Installing MIOpen for deep learning..."
sudo apt install -y miopen-hip miopengemm
echo ""

# Step 9: Verification
echo "Step 9: Verifying ROCm installation..."
echo "Waiting for GPU to initialize..."
sleep 5

if [ -f /opt/rocm/bin/rocminfo ]; then
    echo "Running rocminfo..."
    /opt/rocm/bin/rocminfo | head -20
else
    echo "Warning: rocminfo not found"
fi

echo ""
echo "Running rocm-smi..."
if [ -f /opt/rocm/bin/rocm-smi ]; then
    /opt/rocm/bin/rocm-smi
else
    echo "Warning: rocm-smi not found"
fi

echo ""
echo "=========================================="
echo "ROCm Installation Complete!"
echo "=========================================="
echo ""
echo "IMPORTANT NEXT STEPS:"
echo "1. Log out and log back in for group changes to take effect"
echo "2. Reload your shell configuration: source ~/.bashrc"
echo "3. Run the GPU test: ./tests/test-gpu.sh"
echo "4. Install Ollama: ./scripts/install-ollama.sh"
echo ""
