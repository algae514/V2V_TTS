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
export DEBIAN_FRONTEND=noninteractive
apt-get update || {
    echo -e "${RED}Failed to update package lists${NC}"
    echo -e "${YELLOW}Continuing anyway, but package installation may fail...${NC}"
}

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
    libmecab2 \
    libmecab-dev \
    mecab-ipadic-utf8 \
    pkg-config \
    libssl-dev \
    || {
    echo -e "${RED}Failed to install system dependencies${NC}"
    exit 1
}

# CRITICAL: Configure mecab library cache
echo -e "${GREEN}Configuring mecab library...${NC}"

# Find mecab library location
MECAB_LIB=$(find /usr/lib /usr/local/lib -name "libmecab.so.2*" 2>/dev/null | head -n 1)

if [ -z "$MECAB_LIB" ]; then
    echo -e "${RED}FATAL ERROR: libmecab.so.2 not found after installation!${NC}"
    echo -e "${RED}Package installation failed. Check apt-get output above.${NC}"
    exit 1
fi

MECAB_DIR=$(dirname "$MECAB_LIB")
echo -e "${GREEN}Found mecab library at: $MECAB_LIB${NC}"

# ALWAYS create/overwrite the library config file (ensures it's properly set up)
echo -e "${GREEN}Configuring library path in /etc/ld.so.conf.d/mecab.conf...${NC}"
if [ "$EUID" -eq 0 ]; then
    echo "$MECAB_DIR" > /etc/ld.so.conf.d/mecab.conf
    ldconfig
else
    echo "$MECAB_DIR" | sudo tee /etc/ld.so.conf.d/mecab.conf > /dev/null
    sudo ldconfig 2>/dev/null || ldconfig 2>/dev/null || true
fi

# Wait for cache to update
sleep 2

# Verify library is in cache
if ldconfig -p 2>/dev/null | grep -q "libmecab.so.2"; then
    echo -e "${GREEN}✅ libmecab.so.2 properly configured in library cache${NC}"
else
    echo -e "${YELLOW}WARNING: libmecab.so.2 not in ldconfig cache${NC}"
    echo -e "${YELLOW}The start.sh script will handle this with LD_LIBRARY_PATH${NC}"
fi

# Export for current session
export LD_LIBRARY_PATH="${MECAB_DIR}:${LD_LIBRARY_PATH}"

# Install Rust (needed for tokenizers)
echo -e "${GREEN}Installing Rust compiler...${NC}"
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env" || true
    export PATH="$HOME/.cargo/bin:$PATH"
else
    echo -e "${YELLOW}Rust already installed${NC}"
    source "$HOME/.cargo/env" || true
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Clear cargo registry cache to avoid edition2024 issues
echo -e "${GREEN}Clearing cargo registry cache...${NC}"
rm -rf "$HOME/.cargo/registry" 2>/dev/null || true

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

# Source Rust environment if available
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
    export PATH="$HOME/.cargo/bin:$PATH"
fi

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
# First install base requirements
pip install --no-cache-dir --only-binary=tokenizers -r requirements.txt || {
    echo -e "${RED}Failed to install Python dependencies${NC}"
    exit 1
}

# Install MeloTTS without dependencies to avoid transformers conflict
echo -e "${GREEN}Installing MeloTTS...${NC}"
pip install --no-cache-dir --no-deps git+https://github.com/myshell-ai/MeloTTS.git@main || {
    echo -e "${RED}Failed to install MeloTTS${NC}"
    exit 1
}

# Install MeloTTS dependencies (excluding transformers which is already installed)
echo -e "${GREEN}Installing MeloTTS dependencies...${NC}"
pip install --no-cache-dir --only-binary=tokenizers \
    anyascii==0.3.2 \
    cached_path \
    cn2an==0.5.22 \
    eng_to_ipa==0.0.2 \
    fugashi==1.3.0 \
    g2p_en==2.1.0 \
    'g2pkk>=0.1.1' \
    'gruut[de,es,fr]==2.2.3' \
    inflect==7.0.0 \
    jamo==0.4.1 \
    jieba==0.42.1 \
    langid==1.1.6 \
    librosa==0.9.1 \
    loguru==0.7.2 \
    mecab-python3==1.0.9 \
    num2words==0.5.12 \
    pydub==0.25.1 \
    pykakasi==2.2.1 \
    pypinyin==0.50.0 \
    tensorboard==2.16.2 \
    txtsplit \
    unidecode==1.3.7 \
    unidic==1.1.0 \
    unidic_lite==1.0.8 || {
    echo -e "${YELLOW}Some MeloTTS dependencies failed to install, continuing...${NC}"
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

# Post-installation verification
echo ""
echo -e "${GREEN}[VERIFICATION] Testing installation...${NC}"

# Set full library path for verification
MECAB_LIB=$(find /usr/lib /usr/local/lib -name "libmecab.so.2*" 2>/dev/null | head -n 1)
if [ -n "$MECAB_LIB" ]; then
    MECAB_DIR=$(dirname "$MECAB_LIB")
    export LD_LIBRARY_PATH="${MECAB_DIR}:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/lib:${LD_LIBRARY_PATH}"
fi

# Test 1: mecab library
echo -n "  [1/3] mecab library... "
if LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "import ctypes; ctypes.CDLL('libmecab.so.2')" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo -e "${RED}ERROR: mecab library cannot be loaded!${NC}"
    echo -e "${YELLOW}This will prevent the server from starting.${NC}"
    echo -e "${YELLOW}Try running: ldconfig${NC}"
    exit 1
fi

# Test 2: PyTorch
echo -n "  [2/3] PyTorch + CUDA... "
if python3 -c "import torch; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then
    echo -e "${GREEN}OK (GPU available)${NC}"
elif python3 -c "import torch" 2>/dev/null; then
    echo -e "${YELLOW}OK (CPU only, no CUDA)${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo -e "${RED}ERROR: PyTorch not installed properly!${NC}"
    exit 1
fi

# Test 3: MeloTTS import
echo -n "  [3/3] MeloTTS import... "
if LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "from melo.api import TTS" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo -e "${RED}ERROR: MeloTTS cannot be imported!${NC}"
    echo ""
    echo "Full error:"
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "from melo.api import TTS"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "To start the server, simply run:"
echo -e "  ${GREEN}./start.sh${NC}"
echo ""
echo "The start script will:"
echo "  • Set up all required environment variables"
echo "  • Verify all dependencies"
echo "  • Start the server in the background"
echo ""
echo "You can also start manually:"
echo "  source venv/bin/activate"
echo "  export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/lib:\${LD_LIBRARY_PATH}"
echo "  python3 app.py"
echo ""

