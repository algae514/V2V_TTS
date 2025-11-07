# Quick Start Guide

## ⚡ Automated On-Demand Deployment (One Command)

Perfect for expensive servers you spawn on-demand:

```bash
# Single command - fully automated, non-interactive
cd /workspace && \
git clone https://github.com/algae514/V2V_TTS.git && \
cd V2V_TTS && \
chmod +x setup.sh start.sh stop.sh && \
./setup.sh && \
./start.sh
```

**Done!** Server is running on port 8080 and ready to serve requests.

## 🚀 Deploy on Vast.ai / RunPod in 3 Steps

```bash
# 1. Clone repo
git clone https://github.com/algae514/V2V_TTS.git
cd V2V_TTS

# 2. Setup (one-time, installs everything - fully automated)
chmod +x setup.sh start.sh stop.sh
./setup.sh

# 3. Start server (runs in background)
./start.sh
```

**What's installed automatically:**
- System dependencies (mecab, libmecab2, ffmpeg, sox, etc.)
- Library cache refresh (ldconfig)
- Rust compiler for tokenizers
- Python virtual environment
- PyTorch with GPU auto-detection
- All Python dependencies
- UniDic dictionary
- NLTK data (auto-downloaded on first start)

**No manual intervention required!**

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

