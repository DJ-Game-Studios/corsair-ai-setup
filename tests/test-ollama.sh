#!/bin/bash

# Ollama Test Script for Corsair AI Workstation
# Validate Ollama installation and model inference

set -e

echo "=========================================="
echo "Ollama Test Suite"
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

# Test 1: Ollama Installation
echo "Test 1: Ollama Installation"
if command -v ollama &> /dev/null; then
    OLLAMA_VERSION=$(ollama --version)
    echo "Ollama version: $OLLAMA_VERSION"
    print_status 0 "Ollama installed"
else
    print_status 1 "Ollama not found"
    print_info "Install Ollama: ./scripts/install-ollama.sh"
    exit 1
fi
echo ""

# Test 2: Ollama Service Status
echo "Test 2: Ollama Service Status"
if systemctl is-active --quiet ollama; then
    print_status 0 "Ollama service running"
else
    print_status 1 "Ollama service not running"
    print_info "Start Ollama: sudo systemctl start ollama"
    exit 1
fi
echo ""

# Test 3: Ollama Environment Configuration
echo "Test 3: Ollama Environment Configuration"
if [ -n "$OLLAMA_MODELS" ]; then
    echo "OLLAMA_MODELS: $OLLAMA_MODELS"
    print_status 0 "OLLAMA_MODELS configured"
else
    print_status 1 "OLLAMA_MODELS not set"
    print_info "Set environment variable: export OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models"
fi

if [ -n "$OLLAMA_GPU" ]; then
    echo "OLLAMA_GPU: $OLLAMA_GPU"
    print_status 0 "OLLAMA_GPU configured"
else
    print_status 1 "OLLAMA_GPU not set"
    print_info "Set environment variable: export OLLAMA_GPU=rocm"
fi
echo ""

# Test 4: Model Storage Check
echo "Test 4: Model Storage Check"
STORAGE_PATH=$(eval echo ${OLLAMA_MODELS:-~/.ollama/models})
if [ -d "$STORAGE_PATH" ]; then
    echo "Model storage: $STORAGE_PATH"
    AVAILABLE_SPACE=$(df -h "$STORAGE_PATH" | awk 'NR==2 {print $4}')
    echo "Available space: $AVAILABLE_SPACE"
    print_status 0 "Model storage accessible"
else
    print_status 1 "Model storage not found: $STORAGE_PATH"
    print_info "Create directory: mkdir -p $STORAGE_PATH"
fi
echo ""

# Test 5: List Installed Models
echo "Test 5: List Installed Models"
if ollama list &> /dev/null; then
    echo "Installed models:"
    ollama list
    MODEL_COUNT=$(ollama list | wc -l)
    if [ $MODEL_COUNT -gt 1 ]; then
        print_status 0 "Models installed ($((MODEL_COUNT - 1)) models)"
    else
        print_status 1 "No models installed"
        print_info "Download a model: ollama pull qwen2.5:14b"
    fi
else
    print_status 1 "Failed to list models"
fi
echo ""

# Test 6: Ollama API Test
echo "Test 6: Ollama API Test"
if curl -s http://localhost:11434/api/tags &> /dev/null; then
    print_status 0 "Ollama API responding"
    echo "API endpoint: http://localhost:11434"
else
    print_status 1 "Ollama API not responding"
    print_info "Check Ollama service: sudo systemctl status ollama"
fi
echo ""

# Test 7: Model Inference Test (if models available)
echo "Test 7: Model Inference Test"
FIRST_MODEL=$(ollama list | tail -n +2 | awk '{print $1}' | head -1)
if [ -n "$FIRST_MODEL" ]; then
    echo "Testing inference with model: $FIRST_MODEL"
    echo "Prompt: 'Hello, how are you?'"
    echo ""
    if ollama run "$FIRST_MODEL" "Hello, how are you?" &> /dev/null; then
        print_status 0 "Model inference successful"
        echo ""
        echo "Sample output:"
        ollama run "$FIRST_MODEL" "Hello, how are you?" | head -3
    else
        print_status 1 "Model inference failed"
    fi
else
    print_status 1 "No models available for testing"
    print_info "Download a model first: ollama pull qwen2.5:0.5b"
fi
echo ""

# Test 8: GPU Acceleration Test
echo "Test 8: GPU Acceleration Test"
if [ -n "$OLLAMA_GPU" ] && [ "$OLLAMA_GPU" == "rocm" ]; then
    print_status 0 "GPU acceleration configured (ROCm)"
    if command -v /opt/rocm/bin/rocm-smi &> /dev/null; then
        echo "GPU status:"
        /opt/rocm/bin/rocm-smi | head -10
    fi
else
    print_status 1 "GPU acceleration not configured"
    print_info "Enable GPU acceleration: export OLLAMA_GPU=rocm"
fi
echo ""

# Test 9: Performance Benchmark (optional)
echo "Test 9: Performance Benchmark (Optional)"
if [ -n "$FIRST_MODEL" ]; then
    read -p "Run performance benchmark? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Benchmarking model: $FIRST_MODEL"
        echo "Prompt: 'Write a short poem about AI'"
        echo ""
        time ollama run "$FIRST_MODEL" "Write a short poem about AI"
    else
        echo "Skipping performance benchmark"
    fi
else
    echo "Skipping performance benchmark (no models available)"
fi
echo ""

# Summary
echo "=========================================="
echo "Ollama Test Summary"
echo "=========================================="
echo ""
echo "Key information:"
echo "  - Ollama version: $OLLAMA_VERSION"
echo "  - Model storage: $STORAGE_PATH"
echo "  - GPU acceleration: ${OLLAMA_GPU:-not configured}"
echo "  - Installed models: $((MODEL_COUNT - 1))"
echo ""
echo "For model management, see: docs/model-management.md"
echo "For Ollama troubleshooting, see: docs/ollama-setup.md"
echo ""
