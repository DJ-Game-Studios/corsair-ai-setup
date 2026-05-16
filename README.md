# Corsair AI Workstation Setup

Dedicated setup and configuration repository for the Corsair AI workstation (Node-6: DJ-Linux-GPU_Node-6).

**Hardware:** AMD Ryzen AI Max+ 395 (Strix Halo) - 16 Zen 5 cores, 40 CU RDNA 3.5 GPU, 50 TOPS XDNA 2 NPU, 128GB unified memory

**Purpose:** High-performance AI workstation for 70B+ parameter model inference and training

**Status (as of 2026-05-16):** Node-6 is **LIVE**. ROCm 7.2.3 + Mesa/RADV installed and verified (see [`install-rocm.sh`](scripts/install-rocm.sh)). Primary inference is **llama.cpp `llama-server` + Vulkan/RADV** serving Qwen 3.6 35B-A3B on `:8001` (NOT Ollama — see "Inference runtime choice" below). The repo's setup automation is partially superseded by what's now documented in [`local-ai/HOST_STATUS.md`](https://github.com/DJ-Game-Studios/local-ai/blob/main/HOST_STATUS.md) and [`local-ai/docs/plans/llama-cpp-strix-halo.md`](https://github.com/DJ-Game-Studios/local-ai/blob/main/docs/plans/llama-cpp-strix-halo.md).

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
- **Inference runtime: llama.cpp + Vulkan/RADV** (NOT Ollama). See "Inference runtime choice" below.

## Inference runtime choice (2026-05-15 — supersedes Ollama plan)

Originally this repo's Quick Start pointed at Ollama. That's no longer the recommended path on Node-6. Vetoed during bring-up:

- **Ollama** — bundled llama.cpp can't load the `qwen35` architecture (the Qwen 3.6 35B-A3B GGUF won't deserialize).
- **vLLM on ROCm** — `rocm/vllm:latest` targets MI300 not gfx1151; RDNA 3.5 lacks hardware FP8; bundled transformers pinned <5.0. Full failure log in [`local-ai/docs/plans/vllm-on-rocm-corsair.md`](https://github.com/DJ-Game-Studios/local-ai/blob/main/docs/plans/vllm-on-rocm-corsair.md).

What we run instead — **llama.cpp `llama-server` + Vulkan/RADV** on `:8001`, OpenAI-compatible API, systemd user unit:
- ~64 t/s decode, ~200 t/s prefill on tiny prompts
- Community-validated stack; ~2.5× faster than the best vLLM-on-gfx1151 community fork
- Cross-fleet reachable via Tailscale MagicDNS (`http://dj-node-6.tail1a1945.ts.net:8001/v1`)

Full setup + tuning notes: [`local-ai/docs/plans/llama-cpp-strix-halo.md`](https://github.com/DJ-Game-Studios/local-ai/blob/main/docs/plans/llama-cpp-strix-halo.md).

This repo's `install-ollama.sh` is retained for fleet boxes that still want Ollama (Node-2 currently does), but **don't run it on Node-6** — it'll conflict on storage paths and is the wrong choice for the Qwen 3.6 35B-A3B GGUF we actually serve.

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

**Status:** LIVE (since 2026-05-15) - Ubuntu 26.04 installed, ROCm 7.2.3 verified, llama-server :8001 serving Qwen 3.6 35B-A3B
**Last Updated:** 2026-05-16
