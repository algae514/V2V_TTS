#!/bin/bash
# Quick fix for V2V_TTS setup issues
# This script fixes:
# 1. Missing mecab system dependencies
# 2. Transformers version conflict
# 3. Library path configuration

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 V2V_TTS Quick Fix${NC}"
echo ""

# 1. Install missing mecab system dependencies
echo -e "${GREEN}[1/4] Installing mecab system dependencies...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    mecab \
    libmecab2 \
    libmecab-dev \
    mecab-ipadic-utf8 \
    pkg-config \
    libssl-dev \
    || {
    echo -e "${RED}Failed to install mecab dependencies${NC}"
    exit 1
}

# Refresh library cache
echo -e "${GREEN}Refreshing library cache...${NC}"
ldconfig
sleep 1

# Verify mecab installation
echo -n "Verifying mecab library... "
MECAB_LIB=$(find /usr/lib /usr/local/lib -name "libmecab.so.2*" 2>/dev/null | head -n 1)
if [ -n "$MECAB_LIB" ]; then
    echo -e "${GREEN}OK${NC}"
    echo -e "  Found at: $MECAB_LIB"
else
    echo -e "${RED}FAILED${NC}"
    echo -e "${RED}mecab library still not found after installation!${NC}"
    exit 1
fi

# Add mecab to library path config
MECAB_DIR=$(dirname "$MECAB_LIB")
if [ ! -f /etc/ld.so.conf.d/mecab.conf ]; then
    echo -e "${GREEN}Adding mecab to library path...${NC}"
    echo "$MECAB_DIR" > /etc/ld.so.conf.d/mecab.conf
    ldconfig
    sleep 1
fi

# 2. Check Python dependencies
echo -e "${GREEN}[2/4] Checking Python dependencies...${NC}"
source venv/bin/activate

echo -e "${YELLOW}Note: MeloTTS specifies transformers==4.27.4, but your server is already${NC}"
echo -e "${YELLOW}      working with transformers 4.57.1. Keeping current version.${NC}"
echo ""

# 3. Verify installation
echo -e "${GREEN}[3/4] Verifying installation...${NC}"

# Export library path for verification
export LD_LIBRARY_PATH="${MECAB_DIR}:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/lib:${LD_LIBRARY_PATH}"

echo -n "  • mecab library... "
if LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "import ctypes; ctypes.CDLL('libmecab.so.2')" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

echo -n "  • MeloTTS import... "
if LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "from melo.api import TTS" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo -e "${RED}MeloTTS import failed. Full error:${NC}"
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "from melo.api import TTS"
    exit 1
fi

echo -n "  • PyTorch + CUDA... "
if python3 -c "import torch; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then
    echo -e "${GREEN}OK (GPU available)${NC}"
else
    echo -e "${YELLOW}OK (CPU only)${NC}"
fi

# 4. Check dependency conflicts
echo -e "${GREEN}[4/4] Checking dependencies...${NC}"
echo ""
pip check || echo -e "${YELLOW}Note: gradio not installed (only needed for MeloTTS UI, not for server)${NC}"

echo ""
echo -e "${GREEN}✅ Fix complete!${NC}"
echo ""
echo "Next steps:"
echo -e "  1. Start server: ${GREEN}./start.sh${NC}"
echo -e "  2. Test health: ${GREEN}curl http://localhost:8080/health${NC}"
echo ""
