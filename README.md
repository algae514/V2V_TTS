# MeloTTS Text-to-Speech Server

A production-ready Text-to-Speech server using **MeloTTS** and FastAPI, optimized for GPU-accelerated deployment on cloud platforms like RunPod, AWS, GCP, and Azure.

## ✨ Features

- 🎤 **MeloTTS-English v3** - High-quality neural TTS
- 🚀 **GPU Accelerated** - Automatic CUDA detection with CPU fallback
- 🔌 **RESTful API** - FastAPI-based, production-ready
- 📊 **Health Monitoring** - Built-in health checks
- 🌍 **Cloud Ready** - Works on Vast.ai, RunPod, AWS, GCP, Azure
- ⚡ **Git-Based Deployment** - Simple, fast, and optimized

## 🚀 Quick Start

### Local Development

1. **Clone repository:**
   ```bash
   git clone https://github.com/algae514/V2V_TTS.git
   cd V2V_TTS
   ```

2. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install --upgrade pip
   pip install torch torchaudio
   pip install -r requirements.txt
   ```

4. **Install MeCab (macOS):**
   ```bash
   brew install mecab
   python3 -m unidic download
   ```

5. **Run server:**
   ```bash
   python3 app.py
   ```

6. **Test:**
   ```bash
   curl http://localhost:8080/health
   ```

### Server Deployment (Recommended)

**On Vast.ai, RunPod, or any cloud server:**

```bash
# Clone repository
git clone https://github.com/algae514/V2V_TTS.git
cd V2V_TTS

# Run setup (installs everything automatically)
chmod +x setup.sh start.sh stop.sh
./setup.sh

# Start server
./start.sh

# Test
curl http://localhost:8080/health
```

See [DEPLOY.md](DEPLOY.md) for detailed deployment instructions.

## 📡 API Endpoints

### Health Check
```bash
curl http://localhost:8080/health
```

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "device": "cuda",
  "tts_engine": "MeloTTS"
}
```

### Simple Synthesis
```bash
curl -X POST "http://localhost:8080/tts_simple?text=Hello%20world&speed=1.0" \
  -o output.wav
```

### JSON API
```bash
curl -X POST "http://localhost:8080/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, this is a test", "speed": 1.0}' \
  -o output.wav
```

### Server Info
```bash
curl http://localhost:8080/
```

### Model Information
```bash
curl http://localhost:8080/models
```

## 📦 Project Structure

```
V2V_TTS/
├── app.py                 # Main TTS server (FastAPI)
├── requirements.txt       # Python dependencies
├── setup.sh               # Setup script (installs dependencies)
├── start.sh               # Start server script
├── stop.sh                # Stop server script
├── test_server.sh         # Test script
├── Makefile              # Build automation
├── client_example.py      # Example Python client
├── README.md             # This file
└── DEPLOY.md             # Deployment guide
```

## ⚙️ Configuration

### Environment Variables

- `PORT`: Server port (default: `8080`)
- `TTS_DEVICE`: Device to use - `cuda` or `cpu` (default: auto-detect)
- `TTS_LANGUAGE`: Language code (default: `EN`)

### Custom Port (Optional)

```bash
# Default port is 8080 (automatically freed if occupied)
# To use a different port:
PORT=9090 ./start.sh
```

## 🎮 Server Management

```bash
# Setup (first time)
./setup.sh

# Start server
./start.sh

# Stop server
./stop.sh

# View logs
tail -f logs/tts_server.log

# Test service
./test_server.sh http://localhost:8080

# Or test manually
curl http://localhost:8080/health
```


## 📝 Usage Examples

### Python Client

```python
import requests

# Simple synthesis
response = requests.post(
    "http://localhost:8080/tts_simple",
    params={"text": "Hello from Python", "speed": 1.0}
)

# Save audio
with open("output.wav", "wb") as f:
    f.write(response.content)
```

### JavaScript/Node.js

```javascript
const axios = require('axios');
const fs = require('fs');

async function synthesize(text) {
    const response = await axios.post(
        'http://localhost:8080/tts',
        { text, speed: 1.0 },
        { responseType: 'arraybuffer' }
    );
    fs.writeFileSync('output.wav', response.data);
}
```

## 🔧 Troubleshooting

### GPU Not Detected

```bash
# Check GPU
nvidia-smi

# Use CPU mode
TTS_DEVICE=cpu ./start.sh
```

### Port Already in Use

The start script automatically kills any process using port 8080. If you need to use a different port:

```bash
# Use a different port
PORT=9090 ./start.sh
```

### MeCab/UniDic Issues

The setup script automatically handles MeCab installation. If issues occur:

```bash
# Check MeCab
mecab --version

# Re-download UniDic
source venv/bin/activate
python3 -m unidic download
```

### Model Loading Fails

- Check GPU memory: `nvidia-smi`
- Try CPU mode: `TTS_DEVICE=cpu ./start.sh`
- Check logs: `tail -f logs/tts_server.log`

## 🛡️ Production Considerations

1. **Authentication**: Add API keys or OAuth for public APIs
2. **Rate Limiting**: Implement request throttling
3. **Monitoring**: Set up logging and metrics (Prometheus, Grafana)
4. **Load Balancing**: Use nginx or cloud load balancer
5. **SSL/TLS**: Enable HTTPS with reverse proxy
6. **Caching**: Cache common synthesis requests

## 📚 Documentation

- [DEPLOY.md](DEPLOY.md) - Detailed Git-based deployment guide for Vast.ai, RunPod, AWS, GCP, Azure
- [client_example.py](client_example.py) - Example Python client code

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

## 🔗 Links

- [MeloTTS GitHub](https://github.com/myshell-ai/MeloTTS)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [RunPod](https://www.runpod.io/)

## 📄 License

MIT License - Use freely for personal and commercial projects

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.
