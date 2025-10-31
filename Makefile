# TTS Server Makefile

.PHONY: setup start stop restart logs test health status clean

# Variables
PORT=8080

# Setup server (one-time installation)
setup:
	chmod +x setup.sh start.sh stop.sh
	./setup.sh

# Start server
start:
	./start.sh

# Stop server
stop:
	./stop.sh

# Restart server
restart: stop start

# View logs
logs:
	tail -f logs/tts_server.log

# Check health
health:
	curl http://localhost:$(PORT)/health

# Test the service
test:
	./test_server.sh http://localhost:$(PORT)

# Server status
status:
	@if [ -f tts_server.pid ]; then \
		PID=$$(cat tts_server.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			echo "Server is running (PID: $$PID)"; \
			echo "Port: $(PORT)"; \
			echo "Logs: logs/tts_server.log"; \
		else \
			echo "Server is not running (stale PID file)"; \
			rm -f tts_server.pid; \
		fi; \
	else \
		echo "Server is not running"; \
	fi

# Clean up (remove logs and PID files)
clean:
	rm -f tts_server.pid
	rm -rf logs/*.log
	@echo "Cleaned up runtime files"
