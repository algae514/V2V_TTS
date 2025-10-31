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

# Start server in background
echo -e "${GREEN}Starting server on port $PORT...${NC}"
PORT=$PORT nohup python3 app.py > "$LOG_FILE" 2>&1 &
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

