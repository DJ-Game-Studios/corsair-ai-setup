# SSH Setup Guide

SSH key configuration for the Corsair AI workstation to enable secure fleet-wide authentication.

## Why SSH Keys?

SSH keys provide:
- Secure passwordless authentication
- Fleet-wide access from other nodes
- Integration with existing SSH infrastructure
- Automated access for scripts and tools

## Prerequisites

- Ubuntu 24.04 LTS installed
- SSH server installed (from OS installation guide)
- Tailscale configured (for remote access)
- Access to existing SSH keys from other nodes

## Step 1: Verify SSH Server Installation

```bash
# Check if SSH server is installed
dpkg -l | grep openssh-server

# Install if not present
sudo apt install -y openssh-server

# Enable and start SSH service
sudo systemctl enable ssh
sudo systemctl start ssh

# Check SSH service status
sudo systemctl status ssh
```

## Step 2: Generate SSH Key Pair

If you don't have an existing SSH key:

```bash
# Generate ed25519 key (recommended)
ssh-keygen -t ed25519 -C "dj-linux-gpu-node-6" -f ~/.ssh/id_ed25519

# Or generate RSA key if needed for compatibility
ssh-keygen -t rsa -b 4096 -C "dj-linux-gpu-node-6" -f ~/.ssh/id_rsa
```

If you have existing keys from another node, copy them:

```bash
# Copy from another node (example from main-pc)
scp dj@main-pc:~/.ssh/id_ed25519* ~/.ssh/
scp dj@main-pc:~/.ssh/id_rsa* ~/.ssh/

# Set correct permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

## Step 3: Copy SSH Public Key to Other Nodes

### Option A: Using ssh-copy-id

```bash
# Copy to main-pc
ssh-copy-id dj@main-pc

# Copy to mac-pro
ssh-copy-id dj@mac-pro

# Copy to macbook
ssh-copy-id dj@macbook
```

### Option B: Manual Copy

```bash
# Copy public key content
cat ~/.ssh/id_ed25519.pub

# On each target node, add to authorized_keys
mkdir -p ~/.ssh
echo "<public-key-content>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Option C: Using Tailscale SSH

If using Tailscale SSH, you can use your Tailscale identity:

```bash
# Tailscale SSH uses your Tailscale identity
# No need to copy SSH keys manually
# Just ensure Tailscale SSH is enabled on all nodes
```

## Step 4: Configure SSH Client

Create or update `~/.ssh/config`:

```bash
# Create SSH config directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create SSH config
cat > ~/.ssh/config << 'EOF'
# Fleet nodes
Host main-pc
    HostName main-pc
    User dj
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no

Host mac-pro
    HostName mac-pro
    User dj
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no

Host macbook
    HostName macbook
    User dj
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no

Host dj-linux-gpu-node-6
    HostName dj-linux-gpu-node-6
    User dj-linux-gpu-node-6
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
EOF

chmod 600 ~/.ssh/config
```

## Step 5: Configure SSH Server Settings

Edit `/etc/ssh/sshd_config` for security:

```bash
# Backup original config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Edit SSH config
sudo nano /etc/ssh/sshd_config
```

Recommended settings:

```
# Disable password authentication (key-only)
PasswordAuthentication no

# Disable root login
PermitRootLogin no

# Limit allowed users
AllowUsers dj-linux-gpu-node-6 dj

# Enable key authentication
PubkeyAuthentication yes

# Set idle timeout
ClientAliveInterval 300
ClientAliveCountMax 2
```

Restart SSH after changes:

```bash
# Test new config before restarting
sudo sshd -t

# Restart SSH service
sudo systemctl restart ssh
```

## Step 6: Configure Firewall for SSH

```bash
# Allow SSH through firewall
sudo ufw allow ssh

# Or limit to specific IP ranges (more secure)
sudo ufw allow from 192.168.50.0/24 to any port 22
sudo ufw allow from 100.64.0.0/10 to any port 22  # Tailscale range

# Check firewall status
sudo ufw status
```

## Step 7: Test SSH Connections

```bash
# Test connection to main-pc
ssh main-pc

# Test connection to mac-pro
ssh mac-pro

# Test connection from another node to this node
# From main-pc: ssh dj-linux-gpu-node-6
```

## Step 8: Set Up SSH Agent (Optional)

For convenience with key management:

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# Add to shell configuration
echo 'eval "$(ssh-agent -s)"' >> ~/.bashrc
echo 'ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1' >> ~/.bashrc
```

## Step 9: Configure SSH for Git Operations

If using SSH for Git operations:

```bash
# Add GitHub/GitLab keys
ssh-keygen -t ed25519 -C "dj-linux-gpu-node-6-github" -f ~/.ssh/id_ed25519_github

# Add to GitHub/GitLab settings
cat ~/.ssh/id_ed25519_github.pub

# Configure SSH for GitHub
cat >> ~/.ssh/config << 'EOF'

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
EOF
```

## Fleet SSH Architecture

The fleet uses a shared SSH key infrastructure:

- **Keys**: ed25519 keys for all nodes
- **Config**: Centralized SSH config on each node
- **Access**: Passwordless authentication between nodes
- **Security**: Key-only auth, no password auth
- **Tailscale**: Optional Tailscale SSH as backup

## SSH Aliases and Shortcuts

Create convenient aliases in `~/.bashrc`:

```bash
# SSH shortcuts
alias ssh-main='ssh main-pc'
alias ssh-mac='ssh mac-pro'
alias ssh-macbook='ssh macbook'
alias ssh-node6='ssh dj-linux-gpu-node-6'

# File transfer shortcuts
alias scp-to-main='scp $1 main-pc:~/'
alias scp-from-main='scp main-pc:~/$1 .'
```

## Troubleshooting

### Permission denied (publickey)

```bash
# Check if key exists
ls -la ~/.ssh/

# Check key permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Check if key is loaded in agent
ssh-add -l
```

### Connection refused

```bash
# Check if SSH server is running
sudo systemctl status ssh

# Check if port 22 is open
sudo netstat -tlnp | grep :22

# Check firewall
sudo ufw status
```

### Host key verification failed

```bash
# Remove old host key
ssh-keygen -R <hostname>

# Or disable strict checking (not recommended for production)
# In ~/.ssh/config: StrictHostKeyChecking no
```

### Slow SSH connections

```bash
# Disable DNS lookups in SSH config
echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config

# Restart SSH
sudo systemctl restart ssh
```

## Security Best Practices

1. **Key-only authentication**: Disable password auth
2. **Key rotation**: Rotate keys periodically
3. **Limit users**: Only allow specific users in sshd_config
4. **Monitor logs**: Check `/var/log/auth.log` for suspicious activity
5. **Fail2Ban**: Consider installing fail2ban for brute-force protection

## Next Steps

After SSH setup:

1. **Network Testing:** Run `tests/test-network.sh`
2. **Integration:** Update fleet SSH configs on other nodes
3. **Automation:** Use SSH for automated scripts and backups

## Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [SSH Key Management](https://www.ssh.com/academy/ssh/key)
- [Tailscale SSH](https://tailscale.com/kb/1199/tailscale-ssh/)

---

**Last Updated:** 2026-05-10
