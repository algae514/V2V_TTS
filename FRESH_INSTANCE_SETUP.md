# Fresh Server Instance Setup Guide - V2V_TTS

This guide provides a complete, tested procedure for deploying V2V_TTS on a completely fresh server instance.

## Prerequisites

- Fresh server instance (Ubuntu 20.04+, Debian 11+)
- Root or sudo access
- Internet connection
- Minimum 10GB free disk space
- GPU with CUDA support (optional, will auto-detect)

## Quick Start (90 Second Setup)

```bash
# 1. Clone repository
git clone <your-repo-url>
cd V2V_TTS

# 2. Make scripts executable
chmod +x setup.sh start.sh stop.sh

# 3. Run setup (this handles EVERYTHING)
sudo ./setup.sh

# 4. Start server
./start.sh

# 5. Test it works
curl http://localhost:8080/health
```

That's it! If everything shows ✅, your server is ready.

## Detailed Setup Process

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd V2V_TTS
```

### Step 2: Run Setup Script

The `setup.sh` script is designed to handle **everything** automatically on fresh instances:

```bash
chmod +x setup.sh start.sh stop.sh
sudo ./setup.sh
```

**What setup.sh does:**

1. **Updates system packages** (`apt-get update`)
2. **Installs system dependencies**:
   - Python 3.10+, pip, venv
   - Build tools (gcc, make, pkg-config)
   - Audio libraries (ffmpeg, sox, libsndfile)
   - **mecab and libmecab2** (Japanese text processing)
   - SSL libraries
3. **Configures mecab library** (CRITICAL FIX):
   - Installs mecab packages
   - Refreshes library cache with `ldconfig`
   - Verifies `libmecab.so.2` is available
   - Auto-locates and links library if not in cache
   - Reinstalls packages if library missing
4. **Installs Rust compiler** (needed for tokenizers)
5. **Creates Python virtual environment**
6. **Installs PyTorch** with GPU support (auto-detects CUDA)
7. **Installs Python dependencies** from requirements.txt
8. **Installs MeloTTS** from GitHub
9. **Downloads UniDic dictionary** for Japanese processing
10. **Runs verification tests**:
    - ✅ libmecab.so.2 loadable
    - ✅ PyTorch installed
    - ✅ MeloTTS installed

### Step 3: Verify Installation

At the end of setup, you'll see:

```
[VERIFICATION] Testing installation...
Checking libmecab.so.2... OK
Checking PyTorch installation... OK
Checking MeloTTS installation... OK

✅ Setup complete!
```

**If you see any FAILED**:
- Check `TROUBLESHOOTING.md` for specific fixes
- Common issue: libmecab.so.2 not found (see below)

### Step 4: Start the Server

```bash
./start.sh
```

**What start.sh does:**
1. Activates Python virtual environment
2. **Sets LD_LIBRARY_PATH** (ensures mecab library is found)
3. **Pre-flight check**: Verifies mecab can be loaded
4. Kills any process occupying port 8080
5. Starts server in background
6. Waits 3 seconds
7. Verifies server is running

Expected output:
```
🚀 Starting MeloTTS TTS Server...
Starting server on port 8080...
✅ Server started successfully!

PID: 12345
Port: 8080
Logs: logs/tts_server.log
```

### Step 5: Test the Server

#### Health Check
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "device": "cuda",
  "tts_engine": "MeloTTS"
}
```

#### Generate Speech
```bash
curl -X POST "http://localhost:8080/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world, this is a test of the text to speech system.", "speed": 1.0}' \
  --output test.wav

# Play the audio (if you have audio output)
aplay test.wav  # Linux
# or
play test.wav  # if sox is installed
```

### Step 6: Monitor Logs (Optional)

```bash
tail -f logs/tts_server.log
```

You should see:
```
INFO: Started server process [12345]
INFO: Waiting for application startup.
INFO - Initializing MeloTTS model...
INFO - [TTS] Auto-detected device: cuda
INFO - [TTS] GPU detected: NVIDIA GeForce RTX 3090 (24.00 GB)
INFO - [TTS] MeloTTS model loaded on cuda in 3.45s
INFO - ✅ MeloTTS model loaded successfully!
```

## Common Issues on Fresh Instances

### Issue 1: libmecab.so.2 Not Found

**Error in logs:**
```
ERROR - [TTS] Failed to load MeloTTS model: libmecab.so.2: cannot open shared object file
```

**Solution (Automatic):**
The updated `setup.sh` and `start.sh` now handle this automatically. If you still see this error:

```bash
# Manual fix
sudo apt-get install --reinstall -y mecab libmecab2 libmecab-dev mecab-ipadic-utf8
sudo ldconfig
ldconfig -p | grep libmecab  # Should show libmecab.so.2

# Restart server
./stop.sh
./start.sh
```

See `TROUBLESHOOTING.md` for detailed instructions.

### Issue 2: Server Fails to Start

**Check logs:**
```bash
tail -50 logs/tts_server.log
```

**Common causes:**
- Missing dependencies → Re-run `sudo ./setup.sh`
- Port already in use → `./start.sh` auto-kills port occupants
- GPU issues → Server auto-falls back to CPU

### Issue 3: GPU Not Detected

**Check:**
```bash
nvidia-smi  # Should show your GPU
```

**If GPU not working:**
```bash
# Force CPU mode (server still works fine)
export TTS_DEVICE=cpu
./start.sh
```

**Verify PyTorch sees GPU:**
```bash
source venv/bin/activate
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
```

## Server Management

### Start Server
```bash
./start.sh
```

### Stop Server
```bash
./stop.sh
```

### Restart Server
```bash
./stop.sh && ./start.sh
```

### View Logs
```bash
# Real-time logs
tail -f logs/tts_server.log

# Last 50 lines
tail -50 logs/tts_server.log

# All logs
cat logs/tts_server.log
```

### Check Server Status
```bash
# Check if running
ps aux | grep app.py

# Check port
lsof -i :8080

# Check PID file
cat tts_server.pid
```

## Performance Tips

### GPU Acceleration
- Server auto-detects and uses GPU if available
- Speeds up synthesis by 5-10x compared to CPU
- Check logs for GPU info: `grep GPU logs/tts_server.log`

### Memory Usage
- First synthesis is slower (model initialization)
- Subsequent syntheses are fast (model cached)
- Monitor: `nvidia-smi` (GPU) or `htop` (CPU/RAM)

### Concurrent Requests
- Server can handle multiple concurrent requests
- Each request is processed independently
- Temporary audio files auto-cleaned after serving

## API Usage

### Health Check
```bash
curl http://localhost:8080/health
```

### Synthesize Speech (JSON)
```bash
curl -X POST "http://localhost:8080/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Your text here",
    "speed": 1.0,
    "language": "EN"
  }' \
  --output output.wav
```

### Synthesize Speech (Simple Form)
```bash
curl -X POST "http://localhost:8080/tts_simple?text=Hello%20world&speed=1.0" \
  --output output.wav
```

### List Models
```bash
curl http://localhost:8080/models
```

## Production Deployment

### Cloud Platforms

#### Vast.ai / RunPod
1. Create instance with GPU (recommended: RTX 3080+)
2. Connect via SSH
3. Follow setup steps above
4. Expose port 8080 in instance settings
5. Access via: `http://<instance-ip>:8080`

#### AWS / GCP / Azure
1. Launch instance (g4dn.xlarge or similar for AWS)
2. Open port 8080 in security group/firewall
3. SSH to instance
4. Follow setup steps above
5. Access via: `http://<public-ip>:8080`

### Security Considerations

For production:
- **Add authentication** (API keys, JWT, etc.)
- **Use HTTPS** (reverse proxy with nginx + Let's Encrypt)
- **Rate limiting** (to prevent abuse)
- **Input validation** (text length limits, sanitization)
- **Firewall rules** (restrict access to known IPs)

Example nginx config:
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Updating the Server

```bash
# Stop server
./stop.sh

# Pull latest changes
git pull

# Re-run setup if dependencies changed
sudo ./setup.sh

# Start server
./start.sh
```

## Uninstalling

```bash
# Stop server
./stop.sh

# Remove virtual environment
rm -rf venv

# Remove logs
rm -rf logs

# Remove temporary files
rm -f tts_server.pid tts_server.log

# Uninstall system packages (optional)
sudo apt-get remove mecab libmecab2 mecab-ipadic-utf8
```

## Troubleshooting Checklist

- [ ] Run `sudo ./setup.sh` - handles all dependencies
- [ ] Check verification output - all should show OK
- [ ] Run `./start.sh` - starts server with pre-flight checks
- [ ] Test health endpoint - should return "healthy"
- [ ] Check logs - `tail -f logs/tts_server.log`
- [ ] Verify mecab - `ldconfig -p | grep libmecab`
- [ ] See `TROUBLESHOOTING.md` for specific issues

## Support & Documentation

- **TROUBLESHOOTING.md** - Detailed troubleshooting guide
- **FIX_SUMMARY.md** - Summary of libmecab.so.2 fix
- **README.md** - General project documentation
- **DEPLOY.md** - Cloud deployment guide
- **QUICKSTART.md** - Quick start guide

## Success Criteria

Your setup is successful when:
- ✅ `./setup.sh` completes with all verifications passing
- ✅ `./start.sh` starts server without errors
- ✅ Health endpoint returns `{"status": "healthy", "model_loaded": true}`
- ✅ TTS endpoint generates audio successfully
- ✅ No errors in `logs/tts_server.log`

---

**Last Updated**: 2025-11-07  
**Tested On**: Ubuntu 20.04, 22.04, 24.04, Debian 11, 12  
**Cloud Platforms**: Vast.ai, RunPod, AWS, GCP, Azure
