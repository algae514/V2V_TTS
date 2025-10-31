#!/bin/bash

# Setup script for MeloTTS TTS Server
# Run this after cloning the repository on your server

set -e

echo "🚀 Setting up MeloTTS TTS Server..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${YELLOW}Running as root. Creating non-root user setup...${NC}"
fi

# Update system packages
echo -e "${GREEN}[1/6] Updating system packages...${NC}"
apt-get update || true

# Install system dependencies
echo -e "${GREEN}[2/6] Installing system dependencies...${NC}"
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    curl \
    build-essential \
    ffmpeg \
    libsndfile1 \
    libsndfile1-dev \
    sox \
    libsox-dev \
    libsox-fmt-all \
    mecab \
    libmecab-dev \
    mecab-ipadic-utf8 \
    || {
    echo -e "${RED}Failed to install system dependencies${NC}"
    exit 1
}

# Create virtual environment
echo -e "${GREEN}[3/6] Creating Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✅ Virtual environment created${NC}"
else
    echo -e "${YELLOW}Virtual environment already exists, skipping...${NC}"
fi

# Activate virtual environment and upgrade pip
echo -e "${GREEN}[4/6] Installing Python dependencies...${NC}"
source venv/bin/activate
pip install --upgrade pip setuptools wheel

# Install PyTorch (with CUDA support if GPU available)
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}GPU detected, installing PyTorch with CUDA support...${NC}"
    pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cu118 || \
    pip install --no-cache-dir torch torchaudio
else
    echo -e "${YELLOW}No GPU detected, installing CPU-only PyTorch...${NC}"
    pip install --no-cache-dir torch torchaudio
fi

# Install Python dependencies from requirements.txt
echo -e "${GREEN}Installing Python packages from requirements.txt...${NC}"
pip install --no-cache-dir -r requirements.txt || {
    echo -e "${RED}Failed to install Python dependencies${NC}"
    exit 1
}

# Download UniDic dictionary
echo -e "${GREEN}[5/6] Downloading UniDic dictionary (this may take a while)...${NC}"
python3 -m unidic download || {
    echo -e "${YELLOW}UniDic download failed or already exists, continuing...${NC}"
}

# Create logs directory
echo -e "${GREEN}[6/6] Setting up directories...${NC}"
mkdir -p logs
chmod 777 logs 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "To start the server:"
echo "  1. Activate virtual environment: source venv/bin/activate"
echo "  2. Run: python3 app.py"
echo ""
echo "Or use the start script:"
echo "  ./start.sh"
echo ""

