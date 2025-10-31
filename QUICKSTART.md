# Quick Start Guide

## 🚀 Deploy on Vast.ai / RunPod in 3 Steps

```bash
# 1. Clone repo
git clone https://github.com/algae514/V2V_TTS.git
cd V2V_TTS

# 2. Setup (one-time, installs everything)
chmod +x setup.sh start.sh stop.sh
./setup.sh

# 3. Start server
./start.sh
```

That's it! Server is running on port 8080.

## 🧪 Test

```bash
curl http://localhost:8080/health
```

## 📝 Common Commands

```bash
# Start server
./start.sh

# Stop server
./stop.sh

# View logs
tail -f logs/tts_server.log

# Restart server
./stop.sh && ./start.sh

# Update code
git pull
./stop.sh && ./start.sh
```

## 🔧 Troubleshooting

**Port already in use?**
```bash
# The start script automatically frees port 8080
# If you prefer a different port:
PORT=9090 ./start.sh
```

**GPU not detected?**
- Server auto-detects GPU/CPU
- To force CPU: `TTS_DEVICE=cpu ./start.sh`

**Need help?**
See [DEPLOY.md](DEPLOY.md) for detailed instructions.

