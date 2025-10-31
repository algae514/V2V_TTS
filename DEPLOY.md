# Deployment Guide

Deployment guide for the MeloTTS Text-to-Speech server using Git-based deployment.

## 🚀 Quick Deployment (Recommended)

### Vast.ai / RunPod / Generic Cloud

1. **Clone repository on your server:**
   ```bash
   git clone <your-repo-url>
   cd V2V_TTS
   ```

2. **Run setup script:**
   ```bash
   chmod +x setup.sh start.sh stop.sh
   ./setup.sh
   ```
   This will:
   - Install system dependencies (MeCab, ffmpeg, etc.)
   - Create Python virtual environment
   - Install Python dependencies including PyTorch
   - Download UniDic dictionary
   - Set up directories

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
    libmecab-dev \
    mecab-ipadic-utf8
```

### 2. Clone Repository

```bash
git clone <your-repo-url>
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
   git clone <your-repo-url>
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
   git clone <your-repo-url>
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
sudo apt-get install -y mecab libmecab-dev mecab-ipadic-utf8
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

