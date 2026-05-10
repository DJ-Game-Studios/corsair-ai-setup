#!/bin/bash

# Network Test Script for Corsair AI Workstation
# Validate network connectivity and fleet integration

set -e

echo "=========================================="
echo "Network Test Suite"
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

# Test 1: Network Interface Status
echo "Test 1: Network Interface Status"
if command -v ip &> /dev/null; then
    echo "Network interfaces:"
    ip addr show | grep -E "^[0-9]+:|inet " | head -20
    print_status 0 "Network interfaces detected"
else
    print_status 1 "ip command not found"
fi
echo ""

# Test 2: Local Network Connectivity
echo "Test 2: Local Network Connectivity"
if ping -c 1 -W 2 192.168.50.1 &> /dev/null; then
    print_status 0 "Local gateway reachable"
else
    print_status 1 "Local gateway not reachable"
    print_info "Check network cable and router connection"
fi
echo ""

# Test 3: Internet Connectivity
echo "Test 3: Internet Connectivity"
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
    print_status 0 "Internet connectivity OK"
else
    print_status 1 "Internet connectivity failed"
    print_info "Check DNS and internet connection"
fi
echo ""

# Test 4: DNS Resolution
echo "Test 4: DNS Resolution"
if nslookup google.com &> /dev/null; then
    print_status 0 "DNS resolution working"
else
    print_status 1 "DNS resolution failed"
    print_info "Check DNS configuration in /etc/resolv.conf"
fi
echo ""

# Test 5: SSH Server Status
echo "Test 5: SSH Server Status"
if systemctl is-active --quiet ssh; then
    print_status 0 "SSH server running"
    SSH_PORT=$(sudo netstat -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | sort -u | head -1)
    echo "SSH listening on port: ${SSH_PORT:-22}"
else
    print_status 1 "SSH server not running"
    print_info "Start SSH: sudo systemctl start ssh"
fi
echo ""

# Test 6: Tailscale Status
echo "Test 6: Tailscale Status"
if command -v tailscale &> /dev/null; then
    if systemctl is-active --quiet tailscaled; then
        print_status 0 "Tailscale service running"
        echo "Tailscale status:"
        sudo tailscale status --self 2>/dev/null || echo "Not authenticated"

        # Get Tailscale IP
        TAILSCALE_IP=$(ip addr show tailscale0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        if [ -n "$TAILSCALE_IP" ]; then
            echo "Tailscale IP: $TAILSCALE_IP"
        fi
    else
        print_status 1 "Tailscale service not running"
        print_info "Start Tailscale: sudo systemctl start tailscaled"
    fi
else
    print_status 1 "Tailscale not installed"
    print_info "Install Tailscale: ./scripts/setup-tailscale.sh"
fi
echo ""

# Test 7: Fleet Connectivity (if Tailscale is configured)
echo "Test 7: Fleet Connectivity Test"
FLEET_NODES=("main-pc" "mac-pro" "macbook")
REACHABLE_NODES=0

for node in "${FLEET_NODES[@]}"; do
    if ping -c 1 -W 2 "$node" &> /dev/null; then
        print_status 0 "$node reachable"
        ((REACHABLE_NODES++))
    else
        print_status 1 "$node not reachable"
    fi
done

echo "Fleet connectivity: $REACHABLE_NODES/${#FLEET_NODES[@]} nodes reachable"
echo ""

# Test 8: SSH Connectivity Test
echo "Test 8: SSH Connectivity Test"
if [ $REACHABLE_NODES -gt 0 ]; then
    for node in "${FLEET_NODES[@]}"; do
        if ping -c 1 -W 2 "$node" &> /dev/null; then
            if timeout 5 ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$node" "echo 'SSH OK'" &> /dev/null; then
                print_status 0 "SSH to $node successful"
            else
                print_status 1 "SSH to $node failed"
            fi
        fi
    done
else
    print_status 1 "No fleet nodes reachable for SSH test"
fi
echo ""

# Test 9: Firewall Status
echo "Test 9: Firewall Status"
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "Status: active"; then
        print_status 0 "UFW firewall active"
        echo "Allowed services:"
        sudo ufw status | grep -E "ALLOW|22|11434|41694"
    else
        print_status 1 "UFW firewall not active"
        print_info "Enable firewall: sudo ufw enable"
    fi
else
    print_status 1 "UFW not installed"
    print_info "Install UFW: sudo apt install ufw"
fi
echo ""

# Test 10: Port Scanning (local services)
echo "Test 10: Local Service Ports"
if command -v netstat &> /dev/null; then
    echo "Listening ports:"
    sudo netstat -tlnp 2>/dev/null | grep LISTEN | head -10
    print_status 0 "Port information retrieved"
else
    print_status 1 "netstat command not found"
fi
echo ""

# Test 11: Network Speed Test (optional)
echo "Test 11: Network Speed Test (Optional)"
if command -v speedtest-cli &> /dev/null; then
    read -p "Run network speed test? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        speedtest-cli
    else
        echo "Skipping speed test"
    fi
else
    print_status 1 "speedtest-cli not installed"
    print_info "Install with: sudo apt install speedtest-cli"
fi
echo ""

# Summary
echo "=========================================="
echo "Network Test Summary"
echo "=========================================="
echo ""
echo "Fleet connectivity: $REACHABLE_NODES/${#FLEET_NODES[@]} nodes reachable"
echo "Tailscale IP: ${TAILSCALE_IP:-not configured}"
echo "SSH server: $(systemctl is-active ssh 2>/dev/null || echo 'not running')"
echo "Tailscale: $(systemctl is-active tailscaled 2>/dev/null || echo 'not running')"
echo ""
echo "For network setup, see:"
echo "  - Tailscale: docs/tailscale-setup.md"
echo "  - SSH: docs/ssh-setup.md"
echo ""
