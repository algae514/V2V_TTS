#!/bin/bash

# Stop script for MeloTTS TTS Server

PID_FILE="tts_server.pid"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}No PID file found. Server may not be running.${NC}"
    exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p $PID > /dev/null 2>&1; then
    echo "Stopping server (PID: $PID)..."
    kill $PID
    sleep 2
    
    # Force kill if still running
    if ps -p $PID > /dev/null 2>&1; then
        echo "Force stopping..."
        kill -9 $PID
    fi
    
    rm -f "$PID_FILE"
    echo -e "${GREEN}✅ Server stopped${NC}"
else
    echo -e "${YELLOW}Server is not running${NC}"
    rm -f "$PID_FILE"
fi

