# Fresh Instance Setup Guide

## Expected Timeline

Total time: **5-10 minutes** depending on network and GPU

| Step | Time | What's Happening |
|------|------|------------------|
| System packages | 1-2 min | apt-get installs mecab, ffmpeg, etc. |
| Rust compiler | 30-60 sec | Downloads and installs Rust |
| Python venv | 5 sec | Creates virtual environment |
| PyTorch + CUDA | 1-2 min | Downloads large GPU packages |
| Python deps | 1-2 min | Installs FastAPI, transformers, etc. |
| MeloTTS | 30 sec | Installs TTS engine |
| UniDic dictionary | 1-2 min | Downloads Japanese dictionary |
| Verification | 10 sec | Tests all components |

---

## What to Watch For

### ✅ Good Signs

```
[2/6] Installing system dependencies...
Setting up mecab (0.996-14ubuntu4) ...
Compiling IPA dictionary for Mecab...
```
→ mecab is installing properly

```
Found mecab library at: /usr/lib/x86_64-linux-gnu/libmecab.so.2.0.0
✅ libmecab.so.2 properly configured in library cache
```
→ mecab configured correctly

```
GPU detected, installing PyTorch with CUDA support...
```
→ Will install GPU-accelerated version

```
[VERIFICATION] Testing installation...
  [1/3] mecab library... OK
  [2/3] PyTorch + CUDA... OK (GPU available)
  [3/3] MeloTTS import... OK
```
→ Everything works!

```
✅ Setup complete!
```
→ You're ready to start the server

---

### ⚠️ Warning Signs (Usually OK)

```
WARNING: libmecab.so.2 not in ldconfig cache
The start.sh script will handle this with LD_LIBRARY_PATH
```
→ Not ideal, but start.sh will fix it

```
Rust already installed
```
→ Fine, means Rust was pre-installed

```
Virtual environment already exists, skipping...
```
→ Fine, means you ran setup before

```
melotts 0.1.2 has requirement transformers==4.27.4, but you have transformers 4.57.1
```
→ **Harmless warning**, server works fine with newer version

---

### 🛑 Error Signs (Stop and Fix)

```
ERROR: libmecab.so.2 not found after installation!
FATAL ERROR: Could not find libmecab.so.2
```
→ **FIX:** Run `./quick_fix.sh` OR see `FIX_MECAB_LIBRARY_ERROR.md`

```
Failed to install system dependencies
```
→ **FIX:** Check network, try again: `apt-get install -y mecab libmecab2`

```
ERROR: mecab library cannot be loaded!
```
→ **FIX:** Run `ldconfig` then retry setup

```
ERROR: PyTorch not installed properly!
```
→ **FIX:** Check CUDA compatibility, may need to reinstall PyTorch manually

```
ERROR: MeloTTS cannot be imported!
```
→ **FIX:** Usually mecab issue, run `./quick_fix.sh`

**If setup exits with errors, DO NOT run start.sh yet. Fix the errors first.**

---

## Step-by-Step Commands

### On Fresh Instance:

```bash
# 1. Clone/download the repository (if not already there)
cd /workspace/V2V_TTS

# 2. Run setup (takes 5-10 minutes)
./setup.sh

# Wait for: ✅ Setup complete!
```

**If setup succeeds:**
```bash
# 3. Start the server
./start.sh

# Wait for: ✅ Server started successfully!
```

**If setup fails:**
```bash
# Look for red ERROR messages in output
# Then run the appropriate fix:
./quick_fix.sh

# Then start server:
./start.sh
```

---

## Testing After Start

```bash
# Test 1: Check health
curl http://localhost:8080/health

# Expected: {"status":"healthy","model_loaded":true,"device":"cuda","tts_engine":"MeloTTS"}
```

```bash
# Test 2: Generate test audio
curl -X POST "http://localhost:8080/tts" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello world","speed":1.0}' \
  -o test.wav

# Expected: 200KB+ WAV file created
ls -lh test.wav
```

---

## Common First-Time Issues

### 1. Port 8080 already in use
```bash
# Kill existing process
lsof -ti:8080 | xargs kill -9

# Or use different port
PORT=8081 ./start.sh
```

### 2. Permission denied
```bash
# Make scripts executable
chmod +x setup.sh start.sh stop.sh quick_fix.sh
```

### 3. No GPU detected
If you have a GPU but setup says "No GPU detected":
- Check: `nvidia-smi` (should show GPU)
- Verify CUDA is installed
- Setup will work anyway (CPU mode), but slower

---

## Success Checklist

After setup + start, verify all these:

- [ ] `./setup.sh` completed with "✅ Setup complete!"
- [ ] `./start.sh` shows "✅ Server started successfully!"
- [ ] `curl http://localhost:8080/health` returns `"status":"healthy"`
- [ ] Server logs show "MeloTTS model loaded successfully!"
- [ ] No ERROR messages in `logs/tts_server.log`

If all checked ✅, your server is ready for production use!

---

## Getting Help

If issues persist:

1. Check `logs/tts_server.log` for errors
2. Run: `dpkg -l | grep mecab` (should show 4+ packages)
3. Run: `ps aux | grep python` (should show app.py running)
4. See: `TROUBLESHOOTING.md` for detailed debugging
5. See: `FIX_MECAB_LIBRARY_ERROR.md` for the most common issue
