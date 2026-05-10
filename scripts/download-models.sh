#!/bin/bash

# Model Download Script for Corsair AI Workstation
# Download planned AI models to external storage

set -e

echo "=========================================="
echo "Model Download Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root."
    exit 1
fi

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "Error: Ollama not found. Please install Ollama first: ./scripts/install-ollama.sh"
    exit 1
fi

# Check if OLLAMA_MODELS is set
if [ -z "$OLLAMA_MODELS" ]; then
    echo "Warning: OLLAMA_MODELS environment variable not set."
    echo "Using default location."
    OLLAMA_MODELS="~/.ollama/models"
fi

echo "Model storage location: $OLLAMA_MODELS"
echo ""

# Check available space
STORAGE_PATH=$(eval echo $OLLAMA_MODELS)
if [ -d "$STORAGE_PATH" ]; then
    AVAILABLE_SPACE=$(df -h "$STORAGE_PATH" | awk 'NR==2 {print $4}')
    echo "Available storage space: $AVAILABLE_SPACE"
else
    echo "Warning: Storage path does not exist: $STORAGE_PATH"
fi

echo ""

# Parse command line arguments
PRIORITY=""
MODELS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --priority)
            PRIORITY="$2"
            shift 2
            ;;
        --models)
            MODELS="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Define model lists
HIGH_PRIORITY_MODELS="qwen2.5:0.5b qwen2.5:14b qwen2.5:72b"
MEDIUM_PRIORITY_MODELS="llama3:70b stable-diffusion-xl mistral:7b"
LOW_PRIORITY_MODELS="codellama:34b"

# Select models to download
if [ -n "$MODELS" ]; then
    MODELS_TO_DOWNLOAD="$MODELS"
elif [ "$PRIORITY" == "high" ]; then
    MODELS_TO_DOWNLOAD="$HIGH_PRIORITY_MODELS"
elif [ "$PRIORITY" == "medium" ]; then
    MODELS_TO_DOWNLOAD="$HIGH_PRIORITY_MODELS $MEDIUM_PRIORITY_MODELS"
elif [ "$PRIORITY" == "low" ]; then
    MODELS_TO_DOWNLOAD="$HIGH_PRIORITY_MODELS $MEDIUM_PRIORITY_MODELS $LOW_PRIORITY_MODELS"
else
    echo "No priority specified. Downloading high-priority models only."
    echo "Use --priority {high|medium|low} to download more models."
    echo ""
    read -p "Continue with high-priority models? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    MODELS_TO_DOWNLOAD="$HIGH_PRIORITY_MODELS"
fi

echo "Models to download:"
for model in $MODELS_TO_DOWNLOAD; do
    echo "  - $model"
done
echo ""

# Download models
for model in $MODELS_TO_DOWNLOAD; do
    echo "=========================================="
    echo "Downloading: $model"
    echo "=========================================="

    # Check if model already exists
    if ollama list | grep -q "$model"; then
        echo "Model $model already exists. Skipping."
        echo ""
        continue
    fi

    # Download model
    ollama pull "$model"

    if [ $? -eq 0 ]; then
        echo "Successfully downloaded: $model"
    else
        echo "Error downloading: $model"
        echo "Continuing with next model..."
    fi

    echo ""
done

# Summary
echo "=========================================="
echo "Download Summary"
echo "=========================================="
echo ""
echo "Downloaded models:"
ollama list
echo ""

echo "Model storage usage:"
if [ -d "$STORAGE_PATH" ]; then
    du -sh "$STORAGE_PATH"
else
    echo "Storage path not found: $STORAGE_PATH"
fi

echo ""
echo "=========================================="
echo "Model Download Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test models: ollama run qwen2.5:14b 'Hello!'"
echo "2. Run Ollama tests: ./tests/test-ollama.sh"
echo "3. Monitor GPU usage: watch -n 1 /opt/rocm/bin/rocm-smi"
echo ""
