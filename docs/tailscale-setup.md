# Tailscale Setup Guide

Tailscale mesh network configuration for secure remote access to the Corsair AI workstation.

## Why Tailscale?

Tailscale provides:
- Secure WireGuard-based mesh network
- No need for port forwarding or public IP
- Encrypted peer-to-peer connections
- Integration with existing fleet (main-pc, mac-pro, etc.)
- NAT traversal for remote access

## Prerequisites

- Ubuntu 26.04 installed
- Tailscale account (already set up for the fleet)
- Sudo access
- Stable internet connection

## Step 1: Install Tailscale

```bash
# Add Tailscale repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.gpg | sudo apt-key add -
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.list | sudo tee /etc/apt/sources.list.d/tailscale.list

# Update package list
sudo apt update

# Install Tailscale
sudo apt install -y tailscale
```

## Step 2: Authenticate with Tailscale

```bash
# Start Tailscale and authenticate
sudo tailscale up

# This will:
# 1. Open a browser window (or provide a URL)
# 2. Prompt you to log in to your Tailscale account
# 3. Authorize this machine to join your tailnet
# 4. Assign a Tailscale IP address
```

## Step 3: Configure Tailscale Options

```bash
# Enable SSH access over Tailscale
sudo tailscale up --ssh=server

# Set a custom hostname (optional)
sudo tailscale up --hostname=dj-linux-gpu-node-6

# Advertise exit node (optional, if you want this to be an exit node)
sudo tailscale up --advertise-exit-node

# Accept routes (if configured in Tailscale admin console)
sudo tailscale up --accept-routes
```

## Step 4: Verify Tailscale Connection

```bash
# Check Tailscale status
sudo tailscale status

# Check Tailscale IP address
ip addr show tailscale0

# Test connectivity to other fleet nodes
ping main-pc  # If main-pc is on Tailscale
ping mac-pro   # If mac-pro is on Tailscale
```

## Step 5: Configure Tailscale SSH

```bash
# Enable Tailscale SSH
sudo tailscale up --ssh=server

# This allows SSH access over Tailscale using your Tailscale identity
# No need for separate SSH keys or passwords
```

## Step 6: Configure Firewall for Tailscale

```bash
# Allow Tailscale through firewall
sudo ufw allow 41694/udp  # Tailscale DERP
sudo ufw allow from 100.64.0.0/10  # Tailscale CGNAT range

# Check firewall status
sudo ufw status
```

## Step 7: Set Up Tailscale Systemd Service

Tailscale is automatically configured as a systemd service. Check its status:

```bash
# Check Tailscale service status
sudo systemctl status tailscaled

# Enable Tailscale to start on boot
sudo systemctl enable tailscaled

# Restart Tailscale if needed
sudo systemctl restart tailscaled
```

## Step 8: Configure Tailscale ACLs (Admin Console)

In the Tailscale admin console (https://login.tailscale.com/admin):

1. Navigate to **Access Controls**
2. Add this node to the existing ACL rules
3. Configure which nodes can communicate with this node
4. Set up any required tag-based access controls

Example ACL entry:

```json
{
  "action": "accept",
  "src": ["tag:workstation"],
  "dst": ["tag:ai-node:*"]
}
```

## Step 9: Test Remote Access

From another machine on your Tailscale network:

```bash
# SSH over Tailscale (using Tailscale SSH)
ssh dj-linux-gpu-node-6

# Or using the Tailscale IP
ssh <tailscale-ip>

# Test connectivity
ping dj-linux-gpu-node-6
```

## Tailscale IP Assignment

After authentication, Tailscale will assign an IP in the `100.x.x.x` range. Note this IP for future reference:

```bash
# Get your Tailscale IP
sudo tailscale status --self
```

## Integration with Fleet

This node should join the existing Tailscale fleet:

- **main-pc** (DJ-Linux-Workstation_Node-2)
- **mac-pro** (DJ-Mac-Workstation_Node-3)
- **macbook** (DJ-Mac-Mobile_Node-4)

Verify connectivity:

```bash
# From this node
ping main-pc
ping mac-pro
ping macbook

# From other nodes, they should be able to ping this node
ping dj-linux-gpu-node-6
```

## Tailscale Features

### MagicDNS

MagicDNS allows you to use hostnames instead of IPs:

```bash
# Enable MagicDNS in Tailscale admin console
# Then use hostnames:
ping dj-linux-gpu-node-6
ssh dj-linux-gpu-node-6
```

### Node Naming

Set a consistent hostname:

```bash
# Re-authenticate with custom hostname
sudo tailscale up --hostname=dj-linux-gpu-node-6

# Or rename in Tailscale admin console
```

### Exit Node Configuration

If you want this node to act as an exit node:

```bash
# Advertise as exit node
sudo tailscale up --advertise-exit-node

# Then approve in Tailscale admin console
```

## Troubleshooting

### Tailscale not connecting

```bash
# Check Tailscale status
sudo tailscale status

# Check Tailscale logs
sudo journalctl -u tailscaled -f

# Restart Tailscale
sudo systemctl restart tailscaled
```

### Cannot authenticate

```bash
# Try manual authentication with a link
sudo tailscale up --authkey=<your-auth-key>

# Or generate a new auth key in Tailscale admin console
```

### Firewall blocking Tailscale

```bash
# Check UFW status
sudo ufw status

# Allow Tailscale
sudo ufw allow 41694/udp
sudo ufw allow from 100.64.0.0/10

# Reload firewall
sudo ufw reload
```

### Cannot ping other nodes

```bash
# Check if other nodes are online
sudo tailscale status

# Check ACL rules in Tailscale admin console
# Ensure this node can communicate with others
```

### Tailscale SSH not working

```bash
# Verify SSH is enabled
sudo tailscale status --peers

# Check if SSH server is running
sudo systemctl status ssh

# Restart SSH if needed
sudo systemctl restart ssh
```

## Security Considerations

1. **ACL Rules**: Configure ACLs in Tailscale admin console to restrict access
2. **Key Management**: Use Tailscale's built-in key management
3. **Regular Updates**: Keep Tailscale updated: `sudo apt upgrade tailscale`
4. **Monitor Access**: Regularly review Tailscale admin console for unauthorized devices

## Next Steps

After Tailscale setup:

1. **SSH Configuration:** See `docs/ssh-setup.md`
2. **Network Testing:** Run `tests/test-network.sh`
3. **Integration:** Add node to fleet documentation

## Additional Resources

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale Ubuntu Setup](https://tailscale.com/kb/1180/linux-ubuntu-2204/)
- [Tailscale SSH](https://tailscale.com/kb/1199/tailscale-ssh/)
- [Tailscale ACLs](https://tailscale.com/kb/1038/acls/)

---

**Last Updated:** 2026-05-10
