#!/bin/bash

# GPU Test Script for Corsair AI Workstation
# Validate AMD GPU and ROCm functionality

set -e

echo "=========================================="
echo "GPU Test Suite"
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

print_info() {
    echo -e "${GREEN}ℹ${NC} $1"
}

# Test 1: GPU Detection
echo "Test 1: GPU Detection"
if lspci | grep -qi vga; then
    GPU_INFO=$(lspci | grep -i vga)
    echo "GPU detected: $GPU_INFO"
    print_status 0 "GPU detected"
else
    print_status 1 "No GPU detected"
    exit 1
fi
echo ""

# Test 2: ROCm Installation
echo "Test 2: ROCm Installation"
if [ -f /opt/rocm/bin/rocm-smi ]; then
    print_status 0 "ROCm installed"
else
    print_status 1 "ROCm not found"
    print_info "Install ROCm: ./scripts/install-rocm.sh"
    exit 1
fi
echo ""

# Test 3: ROCm-SMI
echo "Test 3: ROCm-SMI GPU Information"
if /opt/rocm/bin/rocm-smi &> /dev/null; then
    /opt/rocm/bin/rocm-smi
    print_status 0 "ROCm-SMI working"
else
    print_status 1 "ROCm-SMI failed"
    exit 1
fi
echo ""

# Test 4: ROCm Info
echo "Test 4: ROCm Info"
if /opt/rocm/bin/rocminfo &> /dev/null; then
    /opt/rocm/bin/rocminfo | head -30
    print_status 0 "ROCm info retrieved"
else
    print_status 1 "ROCm info failed"
fi
echo ""

# Test 5: HIP Compilation Test
echo "Test 5: HIP Compilation Test"
if command -v hipcc &> /dev/null; then
    cat > /tmp/test_hip.cpp << 'EOF'
#include <hip/hip_runtime.h>
#include <stdio.h>

__global__ void hip_hello() {
    printf("Hello from GPU thread %d!\n", threadIdx.x);
}

int main() {
    hipLaunchKernelGGL(hip_hello, dim3(1), dim3(10), 0, 0);
    hipDeviceSynchronize();
    return 0;
}
EOF

    if hipcc /tmp/test_hip.cpp -o /tmp/test_hip 2>/dev/null; then
        if /tmp/test_hip | grep -q "Hello from GPU"; then
            print_status 0 "HIP compilation and execution successful"
        else
            print_status 1 "HIP execution failed"
        fi
        rm -f /tmp/test_hip /tmp/test_hip.cpp
    else
        print_status 1 "HIP compilation failed"
        print_info "hipcc not found or compilation error"
    fi
else
    print_status 1 "hipcc not found"
    print_info "Install HIP development tools: sudo apt install hip-dev"
fi
echo ""

# Test 6: OpenCL Test
echo "Test 6: OpenCL Test"
if command -v clinfo &> /dev/null; then
    if clinfo &> /dev/null; then
        clinfo | head -20
        print_status 0 "OpenCL working"
    else
        print_status 1 "clinfo failed"
    fi
else
    print_status 1 "clinfo not found"
    print_info "Install OpenCL tools: sudo apt install ocl-icd-opencl-dev clinfo"
fi
echo ""

# Test 7: PyTorch ROCm Test (if installed)
echo "Test 7: PyTorch ROCm Test"
if python3 -c "import torch" 2>/dev/null; then
    if python3 -c "import torch; print(torch.version.hip)" 2>/dev/null; then
        print_status 0 "PyTorch with ROCm support installed"
        python3 -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'ROCm version: {torch.version.hip}')"
    else
        print_status 1 "PyTorch installed but without ROCm support"
        print_info "Install PyTorch with ROCm: pip install torch --index-url https://download.pytorch.org/whl/rocm6.0"
    fi
else
    print_status 1 "PyTorch not installed"
    print_info "Install PyTorch: pip install torch"
fi
echo ""

# Test 8: GPU Memory Test
echo "Test 8: GPU Memory Information"
if /opt/rocm/bin/rocm-smi &> /dev/null; then
    /opt/rocm/bin/rocm-smi --showmem
    print_status 0 "GPU memory information retrieved"
else
    print_status 1 "Could not retrieve GPU memory info"
fi
echo ""

# Test 9: GPU Temperature Test
echo "Test 9: GPU Temperature"
if /opt/rocm/bin/rocm-smi &> /dev/null; then
    /opt/rocm/bin/rocm-smi --showtemp
    print_status 0 "GPU temperature retrieved"
else
    print_status 1 "Could not retrieve GPU temperature"
fi
echo ""

# Summary
echo "=========================================="
echo "GPU Test Summary"
echo "=========================================="
echo ""
echo "If all tests passed, your GPU is properly configured."
echo "If any tests failed, refer to the error messages above."
echo ""
echo "For ROCm troubleshooting, see: docs/rocm-setup.md"
echo ""
