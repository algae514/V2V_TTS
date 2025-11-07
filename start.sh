#!/bin/bash

# Start script for MeloTTS TTS Server
# This script starts the TTS server in the background

set -e

echo "🚀 Starting MeloTTS TTS Server..."

# Configuration
PORT=${PORT:-8080}
LOG_FILE="logs/tts_server.log"
PID_FILE="tts_server.pid"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${RED}Virtual environment not found!${NC}"
    echo "Please run ./setup.sh first"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# CRITICAL: Set up library path for mecab
echo -e "${GREEN}Setting up environment...${NC}"

# Find mecab library location dynamically
MECAB_LIB=$(find /usr/lib /usr/local/lib -name "libmecab.so.2*" 2>/dev/null | head -n 1)

if [ -z "$MECAB_LIB" ]; then
    echo -e "${RED}ERROR: libmecab.so.2 not found!${NC}"
    echo -e "${YELLOW}It appears mecab is not installed.${NC}"
    echo ""
    echo "Please run the setup script first:"
    echo -e "  ${GREEN}./setup.sh${NC}"
    echo ""
    exit 1
fi

MECAB_DIR=$(dirname "$MECAB_LIB")
echo -e "${GREEN}Found mecab library at: ${MECAB_LIB}${NC}"

# Set LD_LIBRARY_PATH to include mecab and standard library locations
export LD_LIBRARY_PATH="${MECAB_DIR}:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/lib:${LD_LIBRARY_PATH}"

# Pre-flight check: Verify mecab library can be loaded
echo -n "Verifying mecab library... "
if LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "import ctypes; ctypes.CDLL('libmecab.so.2')" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo -e "${RED}ERROR: libmecab.so.2 found but cannot be loaded${NC}"
    echo -e "${YELLOW}Trying to refresh library cache...${NC}"
    
    # Try to fix by running ldconfig
    if [ "$EUID" -eq 0 ]; then
        ldconfig
    else
        sudo ldconfig 2>/dev/null || true
    fi
    
    sleep 1
    
    # Test again
    if LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "import ctypes; ctypes.CDLL('libmecab.so.2')" 2>/dev/null; then
        echo -e "${GREEN}Fixed! Library cache refreshed.${NC}"
    else
        echo -e "${RED}Still failing. Please try:${NC}"
        echo "  1. Run: sudo ldconfig"
        echo "  2. Or re-run: ./setup.sh"
        echo ""
        exit 1
    fi
fi

# Verify MeloTTS can be imported
echo -n "Verifying MeloTTS installation... "
if LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" python3 -c "from melo.api import TTS" 2>/dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo -e "${RED}ERROR: MeloTTS cannot be imported${NC}"
    echo -e "${YELLOW}Please run setup again:${NC}"
    echo -e "  ${GREEN}./setup.sh${NC}"
    echo ""
    exit 1
fi

# Check if server is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Server is already running (PID: $OLD_PID)${NC}"
        echo "To stop it: ./stop.sh"
        exit 1
    else
        rm -f "$PID_FILE"
    fi
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Check if port is already in use and kill the process
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    OCCUPYING_PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
    echo -e "${YELLOW}Port $PORT is already in use by PID $OCCUPYING_PID${NC}"
    echo "Killing process on port $PORT..."
    kill -9 $OCCUPYING_PID 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}Port $PORT is now available${NC}"
fi

# Start server in background with proper environment
echo -e "${GREEN}Starting server on port $PORT...${NC}"
echo -e "${GREEN}Environment: LD_LIBRARY_PATH set${NC}"
PORT=$PORT LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" nohup python3 app.py > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

# Save PID
echo $SERVER_PID > "$PID_FILE"

# Wait a moment for server to start
sleep 3

# Check if server is still running
if ps -p $SERVER_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Server started successfully!${NC}"
    echo ""
    echo "PID: $SERVER_PID"
    echo "Port: $PORT"
    echo "Logs: $LOG_FILE"
    echo ""
    echo "Test the server:"
    echo "  curl http://localhost:$PORT/health"
    echo ""
    echo "View logs:"
    echo "  tail -f $LOG_FILE"
    echo ""
    echo "Stop server:"
    echo "  ./stop.sh"
else
    echo -e "${RED}❌ Server failed to start${NC}"
    echo "Check logs: tail -f $LOG_FILE"
    exit 1
fi

