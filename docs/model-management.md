# Model Management Guide

> ⚠️ **OLLAMA-CENTRIC — NOT THE NODE-6 STORY (since 2026-05-15).** On Node-6, model storage is governed by **llama.cpp GGUF pulls** + **ComfyUI safetensors pulls** (imagegen-sandbox), not Ollama. See [`../README.md` § "Inference runtime choice"](../README.md#inference-runtime-choice-2026-05-15--supersedes-ollama-plan).
>
> Live Node-6 model paths:
> - LLM (GGUF): `~/dev/local-ai/models/` (Qwen 3.6 35B-A3B served by llama-server `:8001`)
> - Image gen (safetensors): `~/dev/imagegen-sandbox/models/{diffusion_models,vae,text_encoders,...}/`
>
> SEA-ARC-6TB is **not currently mounted** as `/run/media/dj/SEA-ARC-6TB/ai-models`; that was the original plan and the env-var examples below still reference it. Update or ignore those paths until the drive is plugged in. This doc is retained for fleet boxes that still use the Ollama+external-drive layout (Node-2).

AI model download, management, and optimization for AMD GPU boxes — historical/other-node reference.

## Model Storage Configuration

**Primary Storage:** SEA-ARC-6TB external drive
**Mount Point:** `/run/media/dj/SEA-ARC-6TB/ai-models`
**Capacity:** 6TB (sufficient for 70B+ parameter models)
**Environment Variable:** `OLLAMA_MODELS=/run/media/dj/SEA-ARC-6TB/ai-models`

## Planned Models

### Flagship Models

| Model | Parameters | Size | Purpose | Priority |
|-------|-----------|------|---------|----------|
| qwen2.5:72b | 72B | ~40GB | Primary inference, research | High |
| llama3:70b | 70B | ~40GB | Alternative flagship, Meta ecosystem | High |
| qwen2.5:14b | 14B | ~8GB | Development, testing | High |

### Specialized Models

| Model | Parameters | Size | Purpose | Priority |
|-------|-----------|------|---------|----------|
| stable-diffusion-xl | 3.5B | ~7GB | Image generation | Medium |
| mistral:7b | 7B | ~4GB | Lightweight inference | Medium |
| codellama:34b | 34B | ~20GB | Code generation | Low |

### Test Models

| Model | Parameters | Size | Purpose | Priority |
|-------|-----------|------|---------|----------|
| qwen2.5:0.5b | 0.5B | ~0.3GB | Quick testing, validation | High |
| qwen2.5:1b | 1B | ~0.6GB | Basic testing | Medium |

## Step 1: Verify Storage Configuration

```bash
# Check storage mount point
df -h | grep SEA-ARC-6TB

# Check OLLAMA_MODELS environment variable
echo $OLLAMA_MODELS

# Verify ai-models directory exists
ls -la /run/media/dj/SEA-ARC-6TB/ai-models

# Check available space
df -h /run/media/dj/SEA-ARC-6TB
```

## Step 2: Download First Model (Testing)

```bash
# Download tiny test model
ollama pull qwen2.5:0.5b

# Verify download
ollama list

# Test inference
ollama run qwen2.5:0.5b "Hello, how are you?"
```

## Step 3: Download Development Model

```bash
# Download 14B model for development
ollama pull qwen2.5:14b

# This will take time depending on internet speed
# Monitor progress with: watch -n 1 ollama list
```

## Step 4: Download Flagship Models

```bash
# Download Qwen 2.5 72B (flagship)
ollama pull qwen2.5:72b

# Download Llama 3 70B (alternative flagship)
ollama pull llama3:70b

# Note: These are large downloads (~40GB each)
# Ensure stable internet connection
```

## Step 5: Download Specialized Models

```bash
# Stable Diffusion XL for image generation
ollama pull stable-diffusion-xl

# Mistral 7B for lightweight tasks
ollama pull mistral:7b

# Code Llama for code generation
ollama pull codellama:34b
```

## Model Registry

See `config/models.toml` for the complete model registry with metadata:

```toml
[models.qwen2.5-72b]
name = "qwen2.5:72b"
parameters = "72B"
size_gb = 40
purpose = "Primary inference, research"
priority = "high"
downloaded = false

[models.qwen2.5-14b]
name = "qwen2.5:14b"
parameters = "14B"
size_gb = 8
purpose = "Development, testing"
priority = "high"
downloaded = false
```

## Model Management Commands

### List Models

```bash
# List all installed models
ollama list

# Show model details
ollama show qwen2.5:14b

# Show model information including modelfile
ollama show qwen2.5:14b --modelfile
```

### Remove Models

```bash
# Remove a specific model
ollama rm qwen2.5:0.5b

# Remove multiple models
ollama rm qwen2.5:0.5b qwen2.5:1b

# Remove all test models
ollama rm qwen2.5:0.5b qwen2.5:1b mistral:7b
```

### Model Updates

```bash
# Check for model updates
ollama list  # Shows version information

# Update a model (re-download latest version)
ollama pull qwen2.5:14b
```

## Model Optimization

### Quantization Levels

Ollama automatically uses quantized models. Available levels:

- **Q4_K_M**: 4-bit quantization, good balance of speed and quality
- **Q5_K_M**: 5-bit quantization, better quality
- **Q8_0**: 8-bit quantization, best quality

### GPU Layer Configuration

```bash
# Use more GPU layers for better performance
export OLLAMA_NUM_GPU=99

# Adjust based on available GPU memory
# 112GB available, so 99 is safe for most models
```

### Context Window Configuration

```bash
# Increase context window for longer conversations
export OLLAMA_CTX_SIZE=8192

# For very long contexts
export OLLAMA_CTX_SIZE=32768
```

### Batch Size Tuning

```bash
# Larger batch size for better GPU utilization
export OLLAMA_BATCH_SIZE=512

# Reduce if running out of memory
export OLLAMA_BATCH_SIZE=256
```

## Model Testing

### Basic Inference Test

```bash
# Test with a simple prompt
ollama run qwen2.5:14b "Write a haiku about artificial intelligence"

# Test with a longer prompt
ollama run qwen2.5:14b "Explain quantum computing in simple terms"
```

### Performance Benchmark

```bash
# Time the inference
time ollama run qwen2.5:14b "Write a 500-word essay on AI"

# Monitor GPU usage during inference
watch -n 1 /opt/rocm/bin/rocm-smi
```

### Quality Test

```bash
# Test reasoning capabilities
ollama run qwen2.5:72b "Solve: If 3x + 5 = 20, what is x?"

# Test creative writing
ollama run qwen2.5:72b "Write a short story about a robot learning to paint"

# Test code generation
ollama run codellama:34b "Write a Python function to sort a list"
```

## Model Storage Management

### Check Storage Usage

```bash
# Check total model storage usage
du -sh /run/media/dj/SEA-ARC-6TB/ai-models

# Check per-model usage
du -sh /run/media/dj/SEA-ARC-6TB/ai-models/*

# Check available space
df -h /run/media/dj/SEA-ARC-6TB
```

### Cleanup Unused Models

```bash
# Remove test models after validation
ollama rm qwen2.5:0.5b qwen2.5:1b

# Remove models not used in 30 days
# (Implement based on usage patterns)
```

### Backup Strategy

```bash
# Backup model registry
cp config/models.toml /run/media/dj/SEA-ARC-6TB/ai-models-backup/

# Document which models are essential
# (Keep flagship models, remove test models)
```

## Model Download Script

Use the provided script for automated downloads:

```bash
# Download all planned models
./scripts/download-models.sh

# Download only high-priority models
./scripts/download-models.sh --priority high

# Download specific models
./scripts/download-models.sh --models qwen2.5:14b qwen2.5:72b
```

## Integration with Local AI

This workstation's models are registered in the local-ai configuration:

- **Config file:** `local-ai/configs/hosts/corsair-ai-workstation/models.toml`
- **Status tracking:** Model download status and metadata
- **Cross-reference:** Model usage across the fleet

## Model Performance Expectations

### Qwen 2.5 14B

- **Inference speed:** ~20-30 tokens/sec (GPU accelerated)
- **Memory usage:** ~8GB
- **Quality:** Good for most tasks
- **Use case:** Development, testing

### Qwen 2.5 72B

- **Inference speed:** ~5-10 tokens/sec (GPU accelerated)
- **Memory usage:** ~40GB
- **Quality:** Excellent for complex reasoning
- **Use case:** Research, production

### Llama 3 70B

- **Inference speed:** ~5-10 tokens/sec (GPU accelerated)
- **Memory usage:** ~40GB
- **Quality:** Excellent, Meta ecosystem
- **Use case:** Production, alternative to Qwen

## Troubleshooting

### Download Failures

```bash
# Check internet connection
ping google.com

# Check Ollama service status
sudo systemctl status ollama

# Retry download
ollama pull qwen2.5:14b
```

### Out of Storage Space

```bash
# Check available space
df -h /run/media/dj/SEA-ARC-6TB

# Remove unused models
ollama rm <unused-model>

# Consider upgrading external storage
```

### Slow Inference

```bash
# Check GPU acceleration
echo $OLLAMA_GPU

# Monitor GPU usage
/opt/rocm/bin/rocm-smi

# Increase GPU layers
export OLLAMA_NUM_GPU=99
```

### Model Not Found

```bash
# Check if model is downloaded
ollama list

# Re-download if missing
ollama pull qwen2.5:14b
```

## Next Steps

After model downloads:

1. **Testing:** Run `tests/test-ollama.sh`
2. **Integration:** Configure with local-ai and other tools
3. **Benchmarking:** Measure performance for your use cases

## Additional Resources

- [Ollama Model Library](https://ollama.com/library)
- [Qwen 2.5 Documentation](https://ollama.com/library/qwen2.5)
- [Llama 3 Documentation](https://ollama.com/library/llama3)
- [Model Quantization Guide](https://github.com/ggerganov/llama.cpp/discussions/257)

---

**Last Updated:** 2026-05-10
