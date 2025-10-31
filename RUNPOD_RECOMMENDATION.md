# RunPod Deployment Recommendation for MeloTTS TTS Server

## 🎯 Recommended Configuration

### GPU Selection: **NVIDIA RTX 3090 24GB**

**Why RTX 3090?**
- ✅ **Cost-effective**: $0.14/hour (Community Cloud) or $0.27/hour (Secure Cloud)
- ✅ **Sufficient VRAM**: 24GB is more than enough for MeloTTS inference (~4-8GB needed)
- ✅ **Good performance**: Fast inference with low latency
- ✅ **Popular choice**: Well-supported, widely available

**Alternative Options:**
- **NVIDIA L40S 48GB**: $0.79/hour - If you need extra headroom for multiple models
- **NVIDIA A100 80GB**: $1.99/hour - Overkill for TTS inference, only if doing heavy workloads

### Template Selection: **RunPod PyTorch** or **Ubuntu 22.04**

**Recommended: RunPod PyTorch Template**
- ✅ Pre-installed CUDA and PyTorch
- ✅ GPU drivers already configured
- ✅ Faster setup (skip PyTorch installation)
- ✅ Ready for GPU inference

**Alternative: Basic Ubuntu Template**
- Works fine, but requires full setup
- Takes longer to configure
- Good if you prefer clean slate

### Cloud Type: **Community Cloud** (or Secure Cloud for production)

**Community Cloud** (Recommended for development/testing):
- ✅ Lower cost: $0.14/hour for RTX 3090
- ✅ Good for experimentation
- ✅ Per-second billing (pay only when running)
- ⚠️ May have occasional interruptions

**Secure Cloud** (Recommended for production):
- ✅ Enhanced reliability and uptime
- ✅ Better for production workloads
- ✅ $0.27/hour for RTX 3090 (still affordable)

## 📋 Deployment Steps on RunPod

### 1. Create Pod

1. Go to [RunPod Console](https://www.runpod.io/console)
2. Click **"Pods"** → **"Deploy"**
3. Select:
   - **GPU**: RTX 3090 24GB
   - **Cloud**: Community Cloud (or Secure Cloud)
   - **Template**: `RunPod PyTorch` (search for "pytorch")
   - **Container Disk**: 20GB minimum
   - **Volume Disk**: 20GB (optional, for persistent storage)
   - **Port**: 8080 (for TTS server)

### 2. Connect to Pod

- Click on your pod → **"Connect"**
- Use **SSH** or **Jupyter** to access

### 3. Deploy Code

```bash
# Clone repository
git clone https://github.com/algae514/V2V_TTS.git
cd V2V_TTS

# Setup (one-time)
chmod +x setup.sh start.sh stop.sh
./setup.sh

# Start server
./start.sh
```

### 4. Access Your Service

RunPod provides a public URL for your pod. Access it at:
```
http://your-pod-url:8080/health
```

## 💰 Cost Estimation

**RTX 3090 24GB (Community Cloud):**
- Hourly: $0.14/hour
- Daily (24h): ~$3.36/day
- Monthly (24/7): ~$100/month
- **Per-second billing** means you only pay when the pod is running

**RTX 3090 24GB (Secure Cloud):**
- Hourly: $0.27/hour
- Daily (24h): ~$6.48/day
- Monthly (24/7): ~$194/month

**Cost Optimization Tips:**
1. Use **per-second billing** - stop pods when not in use
2. Use **Community Cloud** for development/testing
3. Consider **Secure Cloud** only for production
4. Stop pods when not actively serving requests

## 🔍 Why RTX 3090 is Perfect for TTS

**MeloTTS Resource Requirements:**
- Model size: ~2-4GB in memory
- Inference VRAM: 4-8GB typical usage
- RTX 3090 provides: 24GB VRAM (3-6x headroom)
- Inference speed: Fast enough for real-time TTS
- Cost: Very affordable at $0.14/hour

**Performance:**
- Can handle multiple concurrent requests
- Low latency inference
- Good throughput for production use

## 📊 Comparison Table

| GPU Model | VRAM | Price/hour | Best For |
|-----------|------|------------|----------|
| **RTX 3090** | 24GB | **$0.14** | ✅ **Recommended for TTS** |
| L40S | 48GB | $0.79 | Extra headroom |
| A100 | 80GB | $1.99 | Overkill, expensive |
| H100 | 80GB | $2.59 | Overkill, expensive |

## ✅ Final Recommendation

**Best Choice for MeloTTS TTS Server:**
- **GPU**: NVIDIA RTX 3090 24GB
- **Cloud**: Community Cloud (or Secure Cloud for production)
- **Template**: RunPod PyTorch
- **Container Disk**: 20GB
- **Port**: 8080

This configuration provides:
- ✅ Excellent performance for TTS inference
- ✅ Cost-effective operation
- ✅ Easy deployment and maintenance
- ✅ Sufficient resources for production workloads

