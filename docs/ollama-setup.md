# Ollama Setup Guide

Ollama installation and configuration for the Corsair AI workstation with AMD GPU acceleration.

## Why Ollama?

Ollama is a powerful tool for running large language models locally with:
- GPU acceleration support (including AMD via ROCm)
- Simple model management API
- REST API for integration with other tools
- Support for multiple model families (Llama, Qwen, Mistral, etc.)

## Prerequisites

- Ubuntu 26.04 installed
- ROCm installed and GPU detected (see `docs/rocm-setup.md`)
- External storage mounted (SEA-ARC-6TB at `/run/media/dj/SEA-ARC-6TB/ai-models`)
- Sudo access

## Step 1: Mount External Storage

```bash
# Create mount point if it doesn't exist
sudo mkdir -p /run/media/dj/SEA-ARC-6TB

# Mount the external drive (adjust device if needed)
sudo mount /dev/sdX1 /run/media/dj/SEA-ARC-6TB

# Create ai-models directory
sudo mkdir -p /run/media/dj/SEA-ARC-6TB/ai-models

# Set ownership
sudo chown -R $USER:$USER /run/media/dj/SEA-ARC-6TB/ai-models

# Verify mount
df -h | grep SEA-ARC-6TB
```

## Step 2: Set Ollama Environment Variables

```bash
# Set OLLAMA_MODELS to point to external storage
echo 'export OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models' >> ~/.bashrc

# Set Ollama to use ROCm for GPU acceleration
echo 'export OLLAMA_GPU=rocm' >> ~/.bashrc

# Reload configuration
source ~/.bashrc
```

## Step 3: Install Ollama

### Option A: Using Official Install Script (Recommended)

```bash
# Download and run the official Ollama install script
curl -fsSL https://ollama.com/install.sh | sh

# This will:
# - Download the latest Ollama binary
# - Install it to /usr/local/bin
# - Create the ollama user
# - Set up systemd service
```

### Option B: Manual Installation

```bash
# Download the latest Ollama binary
wget https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64

# Move to /usr/local/bin
sudo mv ollama-linux-amd64 /usr/local/bin/ollama

# Make executable
sudo chmod +x /usr/local/bin/ollama

# Verify installation
ollama --version
```

## Step 4: Configure Ollama Service

```bash
# Create systemd service override directory
sudo mkdir -p /etc/systemd/system/ollama.service.d

# Create override file with custom environment variables
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models"
Environment="OLLAMA_GPU=rocm"
Environment="OLLAMA_HOST=0.0.0.0"
EOF

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable and start Ollama service
sudo systemctl enable ollama
sudo systemctl start ollama

# Check service status
sudo systemctl status ollama
```

## Step 5: Verify Ollama Installation

```bash
# Check Ollama version
ollama --version

# Check if Ollama service is running
sudo systemctl status ollama

# Check Ollama logs
sudo journalctl -u ollama -f
```

## Step 6: Download First Model

```bash
# Download a small model for testing (qwen2.5:0.5b)
ollama pull qwen2.5:0.5b

# Run a simple test
ollama run qwen2.5:0.5b "Hello, how are you?"
```

## Step 7: Download Planned Models

```bash
# Qwen 2.5 14B (recommended for development)
ollama pull qwen2.5:14b

# Qwen 2.5 72B (flagship model)
ollama pull qwen2.5:72b

# Llama 3 70B
ollama pull llama3:70b

# Stable Diffusion XL (for image generation)
ollama pull stable-diffusion-xl
```

## Step 8: Test GPU Acceleration

```bash
# Run a model with GPU monitoring
ollama run qwen2.5:14b "Write a short poem about AI" &

# Monitor GPU usage in another terminal
watch -n 1 /opt/rocm/bin/rocm-smi
```

## Step 9: Configure Ollama API

Ollama provides a REST API on port 11434 by default. Test it:

```bash
# Test the API
curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5:14b",
  "prompt": "Why is the sky blue?"
}'

# Test the list models endpoint
curl http://localhost:11434/api/tags
```

## Step 10: Configure Firewall for Ollama

```bash
# Allow Ollama API port (if you want remote access)
sudo ufw allow 11434/tcp

# Check firewall status
sudo ufw status
```

## Model Management

### List Installed Models

```bash
# List all installed models
ollama list

# Show model details
ollama show qwen2.5:14b
```

### Remove Models

```bash
# Remove a model
ollama rm qwen2.5:0.5b

# Remove multiple models
ollama rm qwen2.5:0.5b qwen2.5:1b
```

### Model Quantization

Ollama automatically uses quantized models for efficiency. Available quantization levels:

- `:0.5b` - 0.5 billion parameters (tiny, for testing)
- `:1b` - 1 billion parameters (small)
- `:7b` - 7 billion parameters (medium)
- `:14b` - 14 billion parameters (large)
- `:72b` - 72 billion parameters (flagship)

## Performance Optimization

### Set Number of GPU Layers

```bash
# Use more GPU layers for better performance
echo 'export OLLAMA_NUM_GPU=99' >> ~/.bashrc

# Reload configuration
source ~/.bashrc

# Restart Ollama service
sudo systemctl restart ollama
```

### Set Context Window Size

```bash
# Increase context window for longer conversations
echo 'export OLLAMA_CTX_SIZE=8192' >> ~/.bashrc

# Reload configuration
source ~/.bashrc

# Restart Ollama service
sudo systemctl restart ollama
```

### Batch Size Tuning

```bash
# Adjust batch size based on your GPU memory
echo 'export OLLAMA_BATCH_SIZE=512' >> ~/.bashrc

# Reload configuration
source ~/.bashrc

# Restart Ollama service
sudo systemctl restart ollama
```

## Integration with Other Tools

### Python Integration

```bash
# Install Ollama Python library
pip install ollama

# Test Python integration
python3 << EOF
import ollama
response = ollama.generate(model='qwen2.5:14b', prompt='Hello!')
print(response['response'])
EOF
```

### REST API Integration

The Ollama API is compatible with the OpenAI API format. You can use it with:

- LangChain
- LlamaIndex
- Custom applications

Example API endpoint:
```
http://localhost:11434/v1/chat/completions
```

## Troubleshooting

### Ollama not using GPU

```bash
# Check if ROCm is properly configured
echo $OLLAMA_GPU

# Check if GPU is detected
/opt/rocm/bin/rocm-smi

# Check Ollama logs for GPU errors
sudo journalctl -u ollama -n 50
```

### Model storage on wrong drive

```bash
# Check OLLAMA_MODELS environment variable
echo $OLLAMA_MODELS

# Check systemd service override
cat /etc/systemd/system/ollama.service.d/override.conf

# Restart Ollama service after changes
sudo systemctl restart ollama
```

### Out of memory errors

```bash
# Reduce batch size
echo 'export OLLAMA_BATCH_SIZE=256' >> ~/.bashrc

# Reduce number of GPU layers
echo 'export OLLAMA_NUM_GPU=50' >> ~/.bashrc

# Reload and restart
source ~/.bashrc
sudo systemctl restart ollama
```

### Slow inference

```bash
# Increase GPU layers
echo 'export OLLAMA_NUM_GPU=99' >> ~/.bashrc

# Increase batch size
echo 'export OLLAMA_BATCH_SIZE=1024' >> ~/.bashrc

# Reload and restart
source ~/.bashrc
sudo systemctl restart ollama
```

## Model Registry

See `config/models.toml` for the complete model registry with planned models and their purposes.

## Next Steps

After Ollama installation:

1. **Model Downloads:** See `docs/model-management.md`
2. **Testing:** Run `tests/test-ollama.sh`
3. **Integration:** Configure with local-ai and other tools

## Additional Resources

- [Ollama Documentation](https://ollama.com/docs)
- [Ollama Model Library](https://ollama.com/library)
- [Ollama API Reference](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [ROCm Integration](https://ollama.com/docs/gpu)

---

**Last Updated:** 2026-05-10
