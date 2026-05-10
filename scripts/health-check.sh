#!/bin/bash

# Health Check Script for Corsair AI Workstation
# Comprehensive system diagnostics and validation

set -e

echo "=========================================="
echo "Corsair AI Workstation Health Check"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${GREEN}ℹ${NC} $1"
}

# System Information
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo ""

# CPU Information
echo "=== CPU Information ==="
if command -v lscpu &> /dev/null; then
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core" | head -5
    print_status 0 "CPU information retrieved"
else
    print_status 1 "lscpu not found"
fi
echo ""

# Memory Information
echo "=== Memory Information ==="
if command -v free &> /dev/null; then
    free -h
    print_status 0 "Memory information retrieved"
else
    print_status 1 "free command not found"
fi
echo ""

# GPU Detection
echo "=== GPU Detection ==="
if lspci | grep -qi vga; then
    GPU_INFO=$(lspci | grep -i vga)
    echo "GPU detected: $GPU_INFO"
    print_status 0 "GPU detected"
else
    print_status 1 "No GPU detected"
fi
echo ""

# ROCm Status
echo "=== ROCm Status ==="
if [ -f /opt/rocm/bin/rocm-smi ]; then
    /opt/rocm/bin/rocm-smi
    print_status 0 "ROCm installed and running"
else
    print_status 1 "ROCm not found"
    print_warning "Install ROCm: ./scripts/install-rocm.sh"
fi
echo ""

# Storage Information
echo "=== Storage Information ==="
if command -v df &> /dev/null; then
    df -h | grep -E "Filesystem|/$|/home|SEA-ARC"
    print_status 0 "Storage information retrieved"
else
    print_status 1 "df command not found"
fi
echo ""

# External Storage Check
echo "=== External Storage Check ==="
if [ -d /run/media/dj/SEA-ARC-6TB ]; then
    echo "SEA-ARC-6TB mounted at: /run/media/dj/SEA-ARC-6TB"
    if [ -d /run/media/dj/SEA-ARC-6TB/ai-models ]; then
        echo "AI models directory exists"
        print_status 0 "External storage configured"
    else
        print_status 1 "AI models directory missing"
        print_warning "Create directory: sudo mkdir -p /run/media/dj/SEA-ARC-6TB/ai-models"
    fi
else
    print_status 1 "External storage not mounted"
    print_warning "Mount external drive to /run/media/dj/SEA-ARC-6TB"
fi
echo ""

# Ollama Status
echo "=== Ollama Status ==="
if command -v ollama &> /dev/null; then
    echo "Ollama version: $(ollama --version)"
    if systemctl is-active --quiet ollama; then
        print_status 0 "Ollama service running"
    else
        print_status 1 "Ollama service not running"
        print_warning "Start Ollama: sudo systemctl start ollama"
    fi

    if [ -n "$OLLAMA_MODELS" ]; then
        echo "OLLAMA_MODELS: $OLLAMA_MODELS"
        print_status 0 "Ollama environment configured"
    else
        print_status 1 "OLLAMA_MODELS not set"
        print_warning "Set environment variable: export OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models"
    fi

    echo ""
    echo "Installed models:"
    ollama list || echo "No models installed"
else
    print_status 1 "Ollama not found"
    print_warning "Install Ollama: ./scripts/install-ollama.sh"
fi
echo ""

# Tailscale Status
echo "=== Tailscale Status ==="
if command -v tailscale &> /dev/null; then
    if systemctl is-active --quiet tailscaled; then
        print_status 0 "Tailscale service running"
        echo "Tailscale status:"
        sudo tailscale status --self 2>/dev/null || echo "Not authenticated"
    else
        print_status 1 "Tailscale service not running"
        print_warning "Start Tailscale: sudo systemctl start tailscaled"
    fi
else
    print_status 1 "Tailscale not found"
    print_warning "Install Tailscale: ./scripts/setup-tailscale.sh"
fi
echo ""

# SSH Status
echo "=== SSH Status ==="
if systemctl is-active --quiet ssh; then
    print_status 0 "SSH service running"
    echo "SSH listening on port: $(sudo netstat -tlnp | grep sshd | awk '{print $4}' | cut -d: -f2 | sort -u)"
else
    print_status 1 "SSH service not running"
    print_warning "Start SSH: sudo systemctl start ssh"
fi
echo ""

# Network Connectivity
echo "=== Network Connectivity ==="
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
    print_status 0 "Internet connectivity OK"
else
    print_status 1 "Internet connectivity failed"
fi

if ping -c 1 -W 2 192.168.50.1 &> /dev/null; then
    print_status 0 "Local network connectivity OK"
else
    print_status 1 "Local network connectivity failed"
fi
echo ""

# Firewall Status
echo "=== Firewall Status ==="
if command -v ufw &> /dev/null; then
    sudo ufw status | head -5
    print_status 0 "Firewall information retrieved"
else
    print_status 1 "UFW not found"
fi
echo ""

# System Load
echo "=== System Load ==="
if command -v uptime &> /dev/null; then
    uptime
    print_status 0 "System load information retrieved"
else
    print_status 1 "uptime command not found"
fi
echo ""

# Temperature Monitoring (if available)
echo "=== Temperature Monitoring ==="
if command -v sensors &> /dev/null; then
    sensors
    print_status 0 "Temperature sensors available"
else
    print_warning "lm-sensors not installed"
    print_info "Install with: sudo apt install lm-sensors"
fi
echo ""

# Summary
echo "=========================================="
echo "Health Check Summary"
echo "=========================================="
echo ""
echo "For detailed diagnostics, run individual test scripts:"
echo "  - GPU test: ./tests/test-gpu.sh"
echo "  - Ollama test: ./tests/test-ollama.sh"
echo "  - Network test: ./tests/test-network.sh"
echo ""
echo "For installation guides, see docs/ directory"
echo ""
