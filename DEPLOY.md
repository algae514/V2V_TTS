# Deployment Guide

Deployment guide for the MeloTTS Text-to-Speech server using Git-based deployment.

## ⚡ Automated On-Demand Deployment

**Perfect for spawning servers on-demand (Vast.ai, RunPod, etc.):**

This deployment is **100% automated and non-interactive** - ideal for scripts that spawn servers, run setup, and immediately start serving.

```bash
#!/bin/bash
# Single-command automated deployment script
cd /workspace && \
git clone https://github.com/algae514/V2V_TTS.git && \
cd V2V_TTS && \
chmod +x setup.sh start.sh stop.sh && \
./setup.sh && \
./start.sh

# Server will be ready at http://localhost:8080
# No manual intervention required!
```

**What happens automatically:**
1. ✅ System dependencies installed (mecab, libmecab2, ffmpeg, sox, etc.)
2. ✅ Library cache refreshed (ldconfig)
3. ✅ Rust compiler installed for tokenizers
4. ✅ Python virtual environment created
5. ✅ PyTorch installed with GPU auto-detection (CUDA or CPU)
6. ✅ All Python dependencies installed
7. ✅ UniDic dictionary downloaded
8. ✅ NLTK data auto-downloaded on first start
9. ✅ Server starts in background
10. ✅ Ready to serve requests immediately

**Environment Variables (optional):**
```bash
# Override defaults if needed
export PORT=8080                    # Server port (default: 8080)
export TTS_DEVICE=cuda              # Force CUDA or CPU (default: auto-detect)
export TTS_LANGUAGE=EN              # Language code (default: EN)
```

**No classpath setup needed** - everything is self-contained in the virtual environment.

---

## 🚀 Quick Deployment (Recommended)

### Vast.ai / RunPod / Generic Cloud

1. **Clone repository on your server:**
   ```bash
   git clone https://github.com/algae514/V2V_TTS.git
   cd V2V_TTS
   ```

2. **Run setup script:**
   ```bash
   chmod +x setup.sh start.sh stop.sh
   ./setup.sh
   ```
   This will (fully automated, non-interactive):
   - Install system dependencies (mecab, libmecab2, ffmpeg, sox, etc.)
   - Refresh library cache with ldconfig (critical for mecab)
   - Install Rust compiler for tokenizers
   - Create Python virtual environment
   - Auto-detect GPU and install PyTorch with CUDA or CPU
   - Install all Python dependencies
   - Download UniDic dictionary
   - Set up log directories
   - NLTK data auto-downloads on first server start

3. **Start the server:**
   ```bash
   ./start.sh
   ```
   Or manually:
   ```bash
   source venv/bin/activate
   PORT=8080 python3 app.py
   ```

4. **Test:**
   ```bash
   curl http://localhost:8080/health
   ```

5. **Stop the server:**
   ```bash
   ./stop.sh
   ```

## 📋 Step-by-Step Manual Setup

If you prefer to set up manually:

### 1. Install System Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    build-essential \
    ffmpeg \
    libsndfile1 \
    libsndfile1-dev \
    sox \
    libsox-dev \
    mecab \
    libmecab2 \
    libmecab-dev \
    mecab-ipadic-utf8

# CRITICAL: Refresh library cache after mecab installation
sudo ldconfig
```

### 2. Clone Repository

```bash
git clone https://github.com/algae514/V2V_TTS.git
cd V2V_TTS
```

### 3. Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate
```

### 4. Install Python Dependencies

```bash
pip install --upgrade pip setuptools wheel

# Install PyTorch (GPU if available, CPU otherwise)
pip install torch torchaudio

# Install other dependencies
pip install -r requirements.txt
```

### 5. Download UniDic Dictionary

```bash
python3 -m unidic download
```

### 6. Start Server

```bash
# Using start script
./start.sh

# Or manually
PORT=8080 python3 app.py
```

## 🌐 Platform-Specific Instructions

### Vast.ai

1. **Create instance:**
   - Choose Ubuntu 22.04 image
   - Select GPU (RTX 3090 or better recommended)
   - SSH access enabled

2. **Clone and setup:**
   ```bash
   git clone https://github.com/algae514/V2V_TTS.git
   cd V2V_TTS
   ./setup.sh
   ```

3. **Start server:**
   ```bash
   ./start.sh
   ```

4. **Access via SSH tunnel:**
   ```bash
   # On your local machine
   ssh -L 8080:localhost:8080 root@<vast-ai-ip> -p <port>
   # Then access: http://localhost:8080
   ```

### RunPod

1. **Create Pod:**
   - Choose template with Ubuntu
   - Enable SSH/Jupyter access
   - GPU instance

2. **SSH into pod and clone:**
   ```bash
   git clone https://github.com/algae514/V2V_TTS.git
   cd V2V_TTS
   ./setup.sh
   ./start.sh
   ```

3. **Access via RunPod's public URL** (if configured)

### AWS EC2 / GCP / Azure

1. **Launch instance with GPU**
2. **SSH into instance**
3. **Follow "Quick Deployment" steps above**

## ⚙️ Configuration

### Environment Variables

Set these before running the server:

- `PORT`: Server port (default: `8080`)
- `TTS_DEVICE`: `cuda` or `cpu` (default: auto-detect)
- `TTS_LANGUAGE`: Language code (default: `EN`)

Example:
```bash
# Default port is 8080. To use a different port:
PORT=9090 TTS_DEVICE=cuda python3 app.py
```

### Running in Background

```bash
# Using the start script (recommended)
./start.sh

# Or manually with nohup
nohup python3 app.py > logs/server.log 2>&1 &
```

### Running as System Service

Create `/etc/systemd/system/tts-server.service`:

```ini
[Unit]
Description=MeloTTS TTS Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/V2V_TTS
Environment="PATH=/root/V2V_TTS/venv/bin"
ExecStart=/root/V2V_TTS/venv/bin/python3 /root/V2V_TTS/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable tts-server
sudo systemctl start tts-server
sudo systemctl status tts-server
```

## 📊 Monitoring

### View Logs

```bash
# Using start script
tail -f logs/tts_server.log

# Or if running manually
# Logs are written to tts_server.log in the project directory
```

### Check Server Status

```bash
# Check if process is running
ps aux | grep "python3 app.py"

# Check health endpoint
curl http://localhost:8080/health
```

### Restart Server

```bash
./stop.sh
./start.sh
```

## 🔧 Troubleshooting

### Setup Issues

**MeCab installation fails:**
```bash
# Try manual installation
sudo apt-get update
sudo apt-get install -y mecab libmecab2 libmecab-dev mecab-ipadic-utf8

# CRITICAL: Refresh library cache
sudo ldconfig
```

**libmecab.so.2 not found error:**
```bash
# Install the runtime library
sudo apt-get install -y libmecab2
sudo ldconfig

# Restart server
./stop.sh && ./start.sh
```

**UniDic download fails:**
```bash
# Retry download
source venv/bin/activate
python3 -m unidic download
```

**GPU not detected:**
```bash
# Check GPU
nvidia-smi

# Force CPU mode
TTS_DEVICE=cpu python3 app.py
```

### Runtime Issues

**Port already in use:**
```bash
# The start script automatically kills any process using port 8080
# If you prefer to use a different port:
PORT=9090 ./start.sh
```

**Out of memory:**
- Use CPU mode: `TTS_DEVICE=cpu`
- Check GPU memory: `nvidia-smi`
- Reduce batch size in app.py if needed

**Import errors:**
```bash
# Reinstall dependencies
source venv/bin/activate
pip install -r requirements.txt --force-reinstall
```

## 🔄 Updating the Server

```bash
# Pull latest code
git pull

# Reinstall dependencies if needed
source venv/bin/activate
pip install -r requirements.txt --upgrade

# Restart server
./stop.sh
./start.sh
```

## 🔐 Production Considerations

1. **Use systemd service** for auto-restart
2. **Set up monitoring** (Prometheus, Grafana)
3. **Configure firewall** (only expose necessary ports)
4. **Use reverse proxy** (nginx) for HTTPS
5. **Add authentication** if exposing publicly
6. **Set up log rotation** for log files

