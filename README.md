# Corsair AI Workstation Setup

Dedicated setup and configuration repository for the Corsair AI workstation (Node-6: DJ-Linux-GPU_Node-6).

**Hardware:** AMD Ryzen AI Max+ 395 (Strix Halo) - 16 Zen 5 cores, 40 CU RDNA 3.5 GPU, 50 TOPS XDNA 2 NPU, 128GB unified memory

**Purpose:** High-performance AI workstation for 70B+ parameter model inference and training

## Quick Start

```bash
# Clone this repo on the new workstation
git clone https://github.com/DJ-Game-Studios/corsair-ai-setup.git
cd corsair-ai-setup

# Run the full setup
make setup-all

# Or run individual steps
make install-rocm
make install-ollama
make setup-tailscale
make download-models
```

## Directory Structure

```
corsair-ai-setup/
├── README.md                 # This file
├── Makefile                  # Convenient commands for setup tasks
├── docs/                     # Detailed documentation
│   ├── os-installation.md    # Ubuntu 26.04 installation
│   ├── rocm-setup.md         # ROCm driver installation
│   ├── ollama-setup.md       # Ollama installation and configuration
│   ├── tailscale-setup.md    # Tailscale mesh network setup
│   ├── ssh-setup.md          # SSH key configuration
│   └── model-management.md   # Model download and management
├── config/                   # Configuration files
│   ├── hosts.toml            # Host configuration
│   ├── models.toml           # Model registry
│   ├── environment.env      # Environment variables template
│   └── ssh-config.template   # SSH config template
├── scripts/                  # Automation scripts
│   ├── install-rocm.sh       # ROCm installation
│   ├── install-ollama.sh     # Ollama installation
│   ├── setup-tailscale.sh    # Tailscale setup
│   ├── download-models.sh   # Model download script
│   └── health-check.sh       # System health check
└── tests/                    # Validation tests
    ├── test-gpu.sh           # GPU/NPU validation
    ├── test-ollama.sh        # Ollama inference test
    └── test-network.sh       # Network connectivity test
```

## Setup Checklist

- [ ] **OS Installation**: Install Ubuntu 26.04 (see `docs/os-installation.md`)
- [ ] **System Update**: `sudo apt update && sudo apt upgrade -y`
- [ ] **ROCm Installation**: Install AMD GPU drivers (see `docs/rocm-setup.md`)
- [ ] **Tailscale Setup**: Join the fleet mesh network (see `docs/tailscale-setup.md`)
- [ ] **SSH Configuration**: Set up SSH keys and config (see `docs/ssh-setup.md`)
- [ ] **Ollama Installation**: Install and configure Ollama (see `docs/ollama-setup.md`)
- [ ] **External Storage**: Mount SEA-ARC-6TB drive at `/run/media/dj/SEA-ARC-6TB/ai-models`
- [ ] **Model Downloads**: Download first model (qwen2.5:14b recommended)
- [ ] **Health Checks**: Run validation tests (see `tests/`)
- [ ] **Integration**: Register with local-ai, master-track, dj-nodes repos

## Hardware Specifications

**CPU:** AMD Ryzen AI Max+ 395 (Strix Halo)
- 16 Zen 5 cores (32 threads)
- Up to 5.1 GHz boost
- 128KB L1 per core, 1MB L2 per core, 16MB L3

**GPU:** AMD Radeon 8060S (RDNA 3.5)
- 40 Compute Units (2,560 stream processors)
- Unified memory architecture (up to 112GB GPU-allocatable from 128GB total)

**NPU:** AMD XDNA 2
- 50 TOPS AI acceleration
- For low-power AI inference tasks

**Memory:** 128GB LPDDR5x-8000 unified memory
- No separate VRAM bottleneck
- GPU can allocate up to 112GB

**Storage:**
- Internal: (to be determined based on drive selection)
- External: SEA-ARC-6TB (Seagate Expansion 6TB) for AI model storage

## External Storage Configuration

**Drive:** SEA-ARC-6TB (Seagate Expansion 6TB)
**Mount Point:** `/run/media/dj/SEA-ARC-6TB/ai-models`
**Purpose:** AI model weights storage for 70B+ parameter models
**Environment Variable:** `OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models`

## Planned Models

- qwen2.5:72b (72B parameters, flagship model)
- llama3:70b (70B parameters, Meta's flagship)
- qwen2.5:14b (14B parameters, testing/development)
- stable-diffusion-xl (image generation)
- Custom ecosystem models

## Architecture Notes

This workstation uses AMD's unified memory architecture, which means:
- No separate VRAM - GPU shares system memory
- No traditional VRAM bottleneck
- GPU can dynamically allocate up to 112GB from 128GB total
- ROCm drivers required (not CUDA)
- Ollama with ROCm backend for AMD GPU acceleration

## Network Integration

- **Tailscale:** Join the fleet mesh network for secure remote access
- **SSH:** Configure with ed25519 keys for fleet-wide authentication
- **Hostname:** `dj-linux-gpu-node-6-strixhalo` (per naming convention)
- **Username:** `dj-linux-gpu-node-6`
- **Local IP:** To be assigned via DHCP reservation

## Related Repositories

- **local-ai:** Local LLM infrastructure and configuration
  - `local-ai/configs/hosts/corsair-ai-workstation/`
  - `local-ai/docs/setup/corsair-ai-host.md`
- **master-track:** Operational tracking
  - Node ID: `corsair-ai-workstation`
  - Formal name: `DJ-Corsair-AI_Node-6`
- **dj-nodes:** Node registry and profiles
  - `dj-nodes/DJ-Linux-GPU_Node-6/NODE_PROFILE.md`

## Support

For issues or questions about this setup, refer to:
- `docs/` directory for detailed guides
- `scripts/health-check.sh` for system diagnostics
- Parent repo documentation in `local-ai/` and `dj-nodes/`

---

**Status:** PLANNED - Hardware acquired, awaiting OS installation
**Last Updated:** 2026-05-10
