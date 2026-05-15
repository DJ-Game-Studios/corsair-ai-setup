#!/bin/bash
# ROCm Installation Script for Corsair AI Workstation
# AMD Ryzen AI Max+ 395 with Radeon 8060S (RDNA 3.5, gfx1151) on Ubuntu 26.04 (resolute)
#
# This procedure was verified end-to-end on Node-6 2026-05-15 with ROCm 7.2.3.
# History: the original v1 of this script used `apt-key add` (deprecated since 22.04)
# and pinned ROCm 6.0 + the generic `ubuntu main` suite. Both fail on 26.04, and
# 6.0 predates gfx1151 support anyway (Strix Halo needs ≥ 7.2.2).
#
# Path that works on 26.04:
#   - keyring via signed-by (no apt-key)
#   - AMD's /latest pointer over their noble (24.04 LTS) suite — resolute repo is
#     not yet published; noble ABI is compatible because we use the 26.04 inbox
#     amdgpu driver, not AMD's separate DKMS
#   - install the `rocm` meta-package (pulls the full stack incl. rocBLAS gfx1151
#     Tensile kernels)
#   - usermod -aG video,render
#
# See also: dj-nodes/docs/runbooks/sunshine-setup.md for the same "use noble on
# resolute" pattern (Tailscale + Sunshine both required it).

set -e

echo "=========================================="
echo "ROCm Installation Script"
echo "=========================================="
echo ""

# Don't run as root — sudo is used selectively
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root. Use sudo for specific commands."
    exit 1
fi

# Sanity: Ubuntu, 26.04 expected (works on 24.04 too via the same noble repo)
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        echo "Warning: $PRETTY_NAME is not Ubuntu. This script targets Ubuntu 24.04/26.04."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
fi

# Step 1: Verify GPU detection
echo "Step 1: GPU detection"
lspci | grep -iE "vga|display|3d" || { echo "Error: No GPU detected."; exit 1; }
echo ""

# Step 2: Keyring (signed-by — the modern path; `apt-key add` is deprecated)
echo "Step 2: AMD ROCm signing key → /etc/apt/keyrings/rocm.gpg"
sudo install -d /etc/apt/keyrings
wget -qO- https://repo.radeon.com/rocm/rocm.gpg.key \
    | gpg --dearmor \
    | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
echo "  ok"
echo ""

# Step 3: Apt source — AMD's /latest pointer over noble (works on resolute too)
echo "Step 3: Apt source → /etc/apt/sources.list.d/rocm.list"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest noble main" \
    | sudo tee /etc/apt/sources.list.d/rocm.list > /dev/null
cat /etc/apt/sources.list.d/rocm.list
echo ""
echo "Note: pin to a specific version (e.g. /rocm/apt/7.2/ or /rocm/apt/7.2.3/) if"
echo "you want apt update to NOT auto-track ROCm major releases."
echo ""

# Step 4: Pin AMD repo above universe alternatives
echo "Step 4: Apt pin priority 600 for repo.radeon.com"
sudo tee /etc/apt/preferences.d/rocm-pin-600 > /dev/null <<'EOF'
Package: *
Pin: release o=repo.radeon.com
Pin-Priority: 600
EOF
echo "  ok"
echo ""

# Step 5: User → video + render (re-login required for shell groups to update)
echo "Step 5: Add $USER to video,render groups"
sudo usermod -aG video,render "$USER"
echo "  ok — re-login (or 'newgrp render') for the current shell to see the new groups."
echo ""

# Step 6: apt update + install rocm meta-package
echo "Step 6: apt update + install rocm (this is the heavy step; multi-GB download)"
sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y rocm
echo ""

# Step 7: ROCm env on PATH (idempotent — only adds if not already there)
echo "Step 7: ROCm PATH + LD_LIBRARY_PATH in ~/.shell_env (or fallback ~/.bashrc)"
TARGET="$HOME/.shell_env"
[ -f "$TARGET" ] || TARGET="$HOME/.bashrc"
if ! grep -q "rocm/bin" "$TARGET" 2>/dev/null; then
    {
        echo ""
        echo "# ROCm — added by corsair-ai-setup/scripts/install-rocm.sh"
        echo 'export PATH="/opt/rocm/bin:$PATH"'
        echo 'export LD_LIBRARY_PATH="/opt/rocm/lib:${LD_LIBRARY_PATH:-}"'
    } >> "$TARGET"
    echo "  appended to $TARGET"
else
    echo "  already present in $TARGET"
fi
echo ""

# Step 8: Verification — enumerate the GPU and confirm gfx1151 kernels shipped
echo "Step 8: Verifying ROCm install"

echo "  -- rocm-smi (one-line GPU enumeration):"
if [ -x /opt/rocm/bin/rocm-smi ]; then
    /opt/rocm/bin/rocm-smi | grep -E "Device|^[0-9]" | head -5
else
    echo "  WARN: /opt/rocm/bin/rocm-smi not found"
fi
echo ""

echo "  -- rocminfo (gfx target):"
if [ -x /opt/rocm/bin/rocminfo ]; then
    /opt/rocm/bin/rocminfo | grep -E "Name:.*gfx|Marketing Name:" | head -10
else
    echo "  WARN: /opt/rocm/bin/rocminfo not found"
fi
echo ""

echo "  -- rocBLAS gfx1151 Tensile kernels (proof Strix Halo math kernels are shipped):"
if compgen -G "/opt/rocm/lib/rocblas/library/*gfx1151*" > /dev/null; then
    ls /opt/rocm/lib/rocblas/library/ | grep gfx1151 | head -5
    echo "  ✓ gfx1151 kernels present"
else
    echo "  WARN: No gfx1151 kernels found in rocBLAS library — Strix Halo may be unsupported in this ROCm version."
fi
echo ""

echo "=========================================="
echo "ROCm Installation Complete"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo "  1. Re-login (or open a new shell) so $USER's video+render groups take effect."
echo "  2. Reload shell env: 'source ~/.shell_env' (or ~/.bashrc)."
echo "  3. Run: ./scripts/install-ollama.sh"
echo "  4. Test: ./tests/test-gpu.sh"
echo ""
echo "Known issue (gfx1151): amd-smi reports N/A for most monitoring metrics."
echo "Workaround: use rocm-smi instead. ROCm issue tracker: ROCm/ROCm#6035."
echo ""
