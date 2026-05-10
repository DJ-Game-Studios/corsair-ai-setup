# ROCm Setup Guide

AMD ROCm (Radeon Open Compute) installation for GPU acceleration on the Corsair AI workstation.

## Why ROCm?

ROCm is AMD's open-source software platform for GPU-accelerated computing. It provides:
- OpenCL and HIP (HIP is a CUDA-like API)
- Machine learning frameworks support (PyTorch, TensorFlow)
- Optimized for AMD GPUs including the RDNA 3.5 architecture

## Prerequisites

- Ubuntu 24.04 LTS installed
- AMD GPU detected (Radeon 8060S / RDNA 3.5)
- Sudo access
- Stable internet connection

## Step 1: Verify GPU Detection

```bash
# Check if AMD GPU is detected
lspci | grep -i vga
# Expected output: Advanced Micro Devices, Inc. [AMD/ATI] Device ...

# Check GPU details
lspci -nnk | grep -A3 -i vga
```

## Step 2: Install ROCm

### Option A: Using AMD Repository (Recommended)

```bash
# Add AMD ROCm repository
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/6.0/ ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list

# Update package list
sudo apt update

# Install ROCm meta-package
sudo apt install -y rocm-dev rocm-libs rocm-utils

# This will install:
# - ROCm core libraries
# - HIP runtime
# - OpenCL runtime
# - Development tools
# - ROCm utilities
```

### Option B: Using AMDGPU Installer

```bash
# Download AMDGPU installer
wget https://repo.radeon.com/amdgpu-install/6.0/ubuntu/amdgpu-install_6.0.60000-1_all.deb

# Install the package
sudo apt install -y ./amdgpu-install_6.0.60000-1_all.deb

# Install ROCm
sudo amdgpu-install --usecase=rocm,hiplib --no-dkms
```

## Step 3: Configure User Permissions

```bash
# Add your user to the render and video groups
sudo usermod -a -G render,video $USER

# Log out and log back in for group changes to take effect
# Or use: newgrp render
```

## Step 4: Set Environment Variables

Add ROCm paths to your shell configuration:

```bash
# For bash users
echo 'export PATH=$PATH:/opt/rocm/bin:/opt/rocm/opencl/bin' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib' >> ~/.bashrc
echo 'export CPATH=$CPATH:/opt/rocm/include' >> ~/.bashrc

# Reload the configuration
source ~/.bashrc
```

## Step 5: Verify ROCm Installation

```bash
# Check ROCm version
/opt/rocm/bin/rocminfo

# Check GPU information
/opt/rocm/bin/rocm-smi

# Expected output should show:
# - GPU device name
# - Memory information
# - Driver version
# - ROCm version
```

## Step 6: Test ROCm with HIP

```bash
# Create a simple HIP test program
cat > test_hip.cpp << 'EOF'
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

# Compile and run
hipcc test_hip.cpp -o test_hip
./test_hip

# Clean up
rm test_hip.cpp test_hip
```

## Step 7: Install ROCm Python Packages

```bash
# Create a Python virtual environment for ROCm
python3 -m venv ~/rocm-env
source ~/rocm-env/bin/activate

# Install PyTorch with ROCm support
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0

# Verify PyTorch ROCm installation
python3 -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'ROCm available: {torch.version.hip}')"

# Install additional ML packages
pip install numpy scipy scikit-learn

# Deactivate the environment
deactivate
```

## Step 8: Install OpenCL Runtime

```bash
# Install OpenCL ICD loader
sudo apt install -y ocl-icd-opencl-dev

# Verify OpenCL installation
clinfo

# Expected output should show AMD GPU as an OpenCL device
```

## Step 9: Configure ROCm for Deep Learning

```bash
# Install TensorFlow with ROCm support (optional)
pip install tensorflow-rocm

# Install MIOpen (AMD's deep learning library)
sudo apt install -y miopen-hip miopengemm

# Verify MIOpen installation
/opt/rocm/bin/miopen-info
```

## Step 10: Optimize ROCm Performance

```bash
# Set performance tuning environment variables
echo 'export HIP_VISIBLE_DEVICES=0' >> ~/.bashrc
echo 'export HSA_ENABLE_SDMA=0' >> ~/.bashrc

# For better performance on RDNA 3.5
echo 'export GPU_MAX_HEAP_SIZE=100' >> ~/.bashrc
echo 'export GPU_MAX_ALLOC_PERCENT=100' >> ~/.bashrc
echo 'export GPU_SINGLE_ALLOC_PERCENT=100' >> ~/.bashrc

# Reload configuration
source ~/.bashrc
```

## Troubleshooting

### ROCm not detected

```bash
# Check if ROCm kernel modules are loaded
lsmod | grep amdgpu

# If not loaded, try loading them manually
sudo modprobe amdgpu

# Check kernel logs for GPU initialization
dmesg | grep -i amdgpu
```

### Permission denied accessing GPU

```bash
# Verify your user is in the render and video groups
groups $USER

# If not, add them again
sudo usermod -a -G render,video $USER

# Log out and log back in
```

### ROCm-SMI shows no devices

```bash
# Check if GPU is properly detected
lspci -nnk | grep -A3 -i vga

# Check ROCm installation
dpkg -l | grep rocm

# Reinstall ROCm if necessary
sudo apt install --reinstall -y rocm-dev rocm-libs rocm-utils
```

### PyTorch not using ROCm

```bash
# Verify PyTorch was installed with ROCm support
python3 -c "import torch; print(torch.version.hip)"

# If empty, reinstall PyTorch with ROCm
pip uninstall torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0
```

## ROCm-SMI Quick Reference

```bash
# Show GPU status
/opt/rocm/bin/rocm-smi

# Show detailed GPU information
/opt/rocm/bin/rocm-smi --showproductname

# Show memory usage
/opt/rocm/bin/rocm-smi --showmem

# Show temperature and power
/opt/rocm/bin/rocm-smi --showtemp --showpower

# Continuous monitoring (refresh every 1 second)
watch -n 1 /opt/rocm/bin/rocm-smi
```

## Performance Tips

1. **Memory Allocation:** The unified memory architecture allows the GPU to allocate up to 112GB from the 128GB total system memory
2. **Batch Size:** Use larger batch sizes to maximize GPU utilization
3. **Mixed Precision:** Use FP16/BF16 for faster training and inference
4. **HIP vs CUDA:** HIP is compatible with CUDA at the source level, so most CUDA code can be compiled with HIP

## Next Steps

After ROCm installation:

1. **Ollama Installation:** See `docs/ollama-setup.md`
2. **Model Downloads:** See `docs/model-management.md`
3. **Performance Testing:** Run `tests/test-gpu.sh`

## Additional Resources

- [ROCm Documentation](https://rocm.docs.amd.com/)
- [ROCm Installation Guide](https://rocm.docs.amd.com/en/latest/deploy/linux_installer.html)
- [HIP Programming Guide](https://rocm.docs.amd.com/en/latest/HIP/hip.html)
- [PyTorch ROCm](https://pytorch.org/get-started/locally/)

---

**Last Updated:** 2026-05-10
