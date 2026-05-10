# Makefile for Corsair AI Workstation Setup
# Convenient commands for common setup and maintenance tasks

.PHONY: help setup-all install-rocm install-ollama setup-tailscale download-models test-all test-gpu test-ollama test-network health-check clean

# Default target
help:
	@echo "Corsair AI Workstation Setup - Available Commands"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup-all          - Run complete setup (ROCm + Ollama + Tailscale)"
	@echo "  make install-rocm       - Install ROCm (AMD GPU drivers)"
	@echo "  make install-ollama     - Install Ollama (LLM runtime)"
	@echo "  make setup-tailscale    - Configure Tailscale (mesh network)"
	@echo "  make download-models    - Download planned AI models"
	@echo ""
	@echo "Testing Commands:"
	@echo "  make test-all           - Run all tests"
	@echo "  make test-gpu           - Test GPU and ROCm"
	@echo "  make test-ollama       - Test Ollama and models"
	@echo "  make test-network       - Test network and fleet connectivity"
	@echo "  make health-check       - Run comprehensive health check"
	@echo ""
	@echo "Maintenance Commands:"
	@echo "  make clean              - Clean temporary files"
	@echo "  make status             - Show system status"
	@echo ""

# Complete setup
setup-all: install-rocm install-ollama setup-tailscale
	@echo ""
	@echo "=========================================="
	@echo "Complete Setup Finished"
	@echo "=========================================="
	@echo ""
	@echo "Next steps:"
	@echo "1. Log out and log back in for group changes"
	@echo "2. Reload shell: source ~/.bashrc"
	@echo "3. Download models: make download-models"
	@echo "4. Run tests: make test-all"
	@echo ""

# Install ROCm
install-rocm:
	@echo "Installing ROCm..."
	@./scripts/install-rocm.sh

# Install Ollama
install-ollama:
	@echo "Installing Ollama..."
	@./scripts/install-ollama.sh

# Setup Tailscale
setup-tailscale:
	@echo "Setting up Tailscale..."
	@./scripts/setup-tailscale.sh

# Download models
download-models:
	@echo "Downloading AI models..."
	@./scripts/download-models.sh

# Download high-priority models only
download-models-high:
	@echo "Downloading high-priority models..."
	@./scripts/download-models.sh --priority high

# Run all tests
test-all: test-gpu test-ollama test-network
	@echo ""
	@echo "=========================================="
	@echo "All Tests Complete"
	@echo "=========================================="

# Test GPU
test-gpu:
	@echo "Testing GPU and ROCm..."
	@./tests/test-gpu.sh

# Test Ollama
test-ollama:
	@echo "Testing Ollama..."
	@./tests/test-ollama.sh

# Test network
test-network:
	@echo "Testing network connectivity..."
	@./tests/test-network.sh

# Health check
health-check:
	@echo "Running comprehensive health check..."
	@./scripts/health-check.sh

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@rm -f /tmp/test_hip /tmp/test_hip.cpp
	@echo "Clean complete"

# Show system status
status:
	@echo "=== System Status ==="
	@echo "Hostname: $$(hostname)"
	@echo "Kernel: $$(uname -r)"
	@echo "Uptime: $$(uptime -p)"
	@echo ""
	@echo "=== GPU Status ==="
	@if [ -f /opt/rocm/bin/rocm-smi ]; then \
		/opt/rocm/bin/rocm-smi; \
	else \
		echo "ROCm not installed"; \
	fi
	@echo ""
	@echo "=== Ollama Status ==="
	@if command -v ollama > /dev/null 2>&1; then \
		ollama --version; \
		ollama list; \
	else \
		echo "Ollama not installed"; \
	fi
	@echo ""
	@echo "=== Tailscale Status ==="
	@if command -v tailscale > /dev/null 2>&1; then \
		sudo tailscale status --self; \
	else \
		echo "Tailscale not installed"; \
	fi
	@echo ""
	@echo "=== Storage Status ==="
	@df -h | grep -E "Filesystem|/$|/home|SEA-ARC"
