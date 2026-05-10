# OS Installation Guide

Ubuntu 26.04 installation for the Corsair AI workstation (AMD Ryzen AI Max+ 395).

## Prerequisites

- Ubuntu 26.04 ISO image
- USB flash drive (8GB+)
- Another computer to create the bootable media
- Stable internet connection during installation

## Why Ubuntu 26.04?

- **ROCm Support:** Ubuntu 26.04 has excellent ROCm (AMD GPU driver) support
- **Fleet Consistency:** Matches other nodes (Node-1, Node-2) running Ubuntu 26.04
- **Modern Kernel:** Linux 7.x with better AMD GPU support
- **Package Availability:** Latest versions of AI/ML tools in repositories

## Step 1: Download Ubuntu 26.04

```bash
# Download the latest Ubuntu 26.04 ISO
wget https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso

# Verify the download (optional but recommended)
sha256sum ubuntu-26.04-desktop-amd64.iso
```

## Step 2: Create Bootable USB

Using **balenaEtcher** (recommended for ease of use):

1. Download balenaEtcher from https://etcher.balena.io/
2. Flash the ISO to your USB drive
3. Safely eject the USB drive

Or using **dd** (Linux/macOS):

```bash
# Identify your USB drive (e.g., /dev/sdX)
lsblk

# Flash the ISO (replace /dev/sdX with your USB device)
sudo dd if=ubuntu-26.04-desktop-amd64.iso of=/dev/sdX bs=4M status=progress conv=fdatasync

# Sync and eject
sync
sudo eject /dev/sdX
```

## Step 3: Boot from USB

1. Insert the USB drive into the Corsair AI workstation
2. Power on the workstation
3. Enter the boot menu (typically F12, F11, or F2, depending on motherboard)
4. Select the USB drive as the boot device
5. Choose "Try or Install Ubuntu" from the boot menu

## Step 4: Installation Steps

### 4.1 Language and Keyboard

- Language: English
- Keyboard layout: US (or your preferred layout)

### 4.2 Installation Type

Choose **"Normal installation"** (recommended for AI workstation):
- Includes web browser, utilities, and software
- Better for development work

### 4.3 Disk Configuration

**Option A: Clean Install (Recommended)**
- Select "Erase disk and install Ubuntu"
- This will wipe the entire disk
- Ensure you have backed up any important data

**Option B: Manual Partitioning**
- If you want to preserve existing data or create custom partitions
- Recommended partition scheme for AI workstation:
  - `/` (root): 100GB+ (ext4)
  - `/home`: Remaining space (ext4)
  - Swap: 32GB (for hibernation and large model workloads)

### 4.4 User Account

Following the node naming convention:

- **Your name:** DJ Linux GPU Node 6
- **Computer name:** `dj-linux-gpu-node-6-strixhalo`
- **Username:** `dj-linux-gpu-node-6`
- **Password:** (use the shared PCPOWER series password from Bitwarden)

### 4.5 Installation Summary

Review the installation settings and click **"Install Now"**.

## Step 5: Post-Installation Steps

### 5.1 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 5.2 Install Essential Packages

```bash
# Development tools
sudo apt install -y build-essential git curl wget vim htop tmux

# Python and AI/ML basics
sudo apt install -y python3 python3-pip python3-venv

# System monitoring
sudo apt install -y neofetch glances

# Network tools
sudo apt install -y net-tools openssh-server
```

### 5.3 Enable SSH Server

```bash
# Install SSH server
sudo apt install -y openssh-server

# Enable and start SSH service
sudo systemctl enable ssh
sudo systemctl start ssh

# Verify SSH is running
sudo systemctl status ssh
```

### 5.4 Configure Firewall

```bash
# Enable UFW (Uncomplicated Firewall)
sudo ufw enable

# Allow SSH
sudo ufw allow ssh

# Check status
sudo ufw status
```

### 5.5 Verify Hardware Detection

```bash
# Check CPU
lscpu

# Check memory
free -h

# Check GPU (should detect AMD GPU)
lspci | grep -i vga

# Check for NPU (may not be detected until ROCm is installed)
lspci | grep -i amd
```

## Step 6: Network Configuration

### 6.1 Wired Connection (Recommended)

For AI workloads, use a wired Ethernet connection for stability and bandwidth.

### 6.2 Configure Static IP (Optional)

If you want a static IP for the workstation:

```bash
# Edit Netplan configuration
sudo nano /etc/netplan/00-installer-config.yaml

# Example configuration:
network:
  version: 2
  renderer: networkd
  ethernets:
    eno1:
      dhcp4: no
      addresses:
        - 192.168.50.130/24  # Choose an IP in your network range
      routes:
        - to: default
          via: 192.168.50.1   # Your router IP
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Apply the configuration
sudo netplan apply
```

## Step 7: Clone This Repository

```bash
# Install git if not already installed
sudo apt install -y git

# Clone the corsair-ai-setup repository
cd ~
git clone https://github.com/djmsqrvve/corsair-ai-setup.git

# Navigate to the repository
cd corsair-ai-setup
```

## Step 8: Verify Installation

Run the health check script to verify the OS installation:

```bash
cd ~/corsair-ai-setup
./scripts/health-check.sh
```

## Next Steps

After completing the OS installation:

1. **ROCm Installation:** See `docs/rocm-setup.md`
2. **Tailscale Setup:** See `docs/tailscale-setup.md`
3. **SSH Configuration:** See `docs/ssh-setup.md`
4. **Ollama Installation:** See `docs/ollama-setup.md`
5. **Model Downloads:** See `docs/model-management.md`

## Troubleshooting

### Boot Issues

If the system doesn't boot from USB:
- Check BIOS/UEFI boot order
- Disable Secure Boot (temporarily) if needed
- Try a different USB port

### GPU Not Detected

If the AMD GPU is not detected:
- Ensure you're using the correct kernel version
- Check for BIOS updates
- Verify the GPU is properly seated

### Network Issues

If network configuration fails:
- Try DHCP first (automatic IP assignment)
- Check cable connections
- Verify router settings

## Additional Resources

- [Ubuntu Release Notes](https://discourse.ubuntu.com/)
- [AMD ROCm Installation Guide](https://rocm.docs.amd.com/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

---

**Last Updated:** 2026-05-10
