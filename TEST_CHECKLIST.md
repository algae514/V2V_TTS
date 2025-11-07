# Testing Checklist for Fresh Server Instance

Use this checklist when testing the fix on a fresh server instance.

## Pre-Test Preparation

- [ ] Have access to a fresh Ubuntu 20.04+ or Debian 11+ server
- [ ] Have root/sudo access
- [ ] Have SSH access
- [ ] Server has internet connectivity
- [ ] Server has at least 10GB free disk space
- [ ] (Optional) Server has GPU with CUDA support

## Test Procedure

### Phase 1: Initial Setup

- [ ] **SSH to fresh server**
  ```bash
  ssh user@server-ip
  ```

- [ ] **Clone repository**
  ```bash
  git clone <your-repo-url>
  cd V2V_TTS
  ```

- [ ] **Make scripts executable**
  ```bash
  chmod +x setup.sh start.sh stop.sh
  ```

### Phase 2: Run Setup

- [ ] **Run setup.sh**
  ```bash
  sudo ./setup.sh
  ```

- [ ] **Watch for system dependencies installation**
  - Should see: `[2/6] Installing system dependencies...`
  - Should include: mecab, libmecab2, ffmpeg, sox, etc.

- [ ] **Watch for mecab library configuration**
  - Should see: `Refreshing library cache and verifying mecab installation...`
  - Should see: `✅ libmecab.so.2 is properly configured`
  - **If you see WARNING here, note it down**

- [ ] **Watch for verification tests**
  - Should see: `[VERIFICATION] Testing installation...`
  - Check libmecab.so.2: Should show `OK` (not `FAILED`)
  - Check PyTorch: Should show `OK`
  - Check MeloTTS: Should show `OK`
  - **If any show FAILED, note it down**

- [ ] **Setup completes without errors**
  - Should see: `✅ Setup complete!`

### Phase 3: Start Server

- [ ] **Run start.sh**
  ```bash
  ./start.sh
  ```

- [ ] **Pre-flight check passes**
  - Should NOT see: `ERROR: libmecab.so.2 not found`
  - **If you see this error, the fix failed - note details**

- [ ] **Server starts successfully**
  - Should see: `✅ Server started successfully!`
  - Should show PID, Port (8080), and log file location

- [ ] **Wait 5 seconds for model to load**
  ```bash
  sleep 5
  ```

### Phase 4: Verify Server Health

- [ ] **Check health endpoint**
  ```bash
  curl http://localhost:8080/health
  ```
  - Expected response:
    ```json
    {
      "status": "healthy",
      "model_loaded": true,
      "device": "cuda" or "cpu",
      "tts_engine": "MeloTTS"
    }
    ```
  - **If status is not "healthy", note the response**

- [ ] **Check root endpoint**
  ```bash
  curl http://localhost:8080/
  ```
  - Should return service info with `"ready": true`

### Phase 5: Test TTS Synthesis

- [ ] **Test simple TTS**
  ```bash
  curl -X POST "http://localhost:8080/tts" \
    -H "Content-Type: application/json" \
    -d '{"text": "Hello world", "speed": 1.0}' \
    --output test.wav
  ```
  - Should create `test.wav` file
  - File should be > 0 bytes
  - **If request fails, note the error message**

- [ ] **Verify audio file created**
  ```bash
  ls -lh test.wav
  file test.wav
  ```
  - Should show: `RIFF (little-endian) data, WAVE audio`
  - File size should be > 50KB

- [ ] **Test longer text**
  ```bash
  curl -X POST "http://localhost:8080/tts" \
    -H "Content-Type: application/json" \
    -d '{"text": "This is a longer test to verify the text to speech system works correctly with multiple sentences.", "speed": 1.0}' \
    --output test2.wav
  ```
  - Should succeed without errors

### Phase 6: Check Logs

- [ ] **View server logs**
  ```bash
  tail -50 logs/tts_server.log
  ```

- [ ] **Verify no libmecab errors**
  ```bash
  grep -i "libmecab" logs/tts_server.log
  ```
  - Should NOT show: `cannot open shared object file`
  - **If it does, the fix failed - note the full error**

- [ ] **Verify model loaded successfully**
  ```bash
  grep "MeloTTS model loaded" logs/tts_server.log
  ```
  - Should show: `✅ MeloTTS model loaded successfully!`
  - Should show device (cuda or cpu)

- [ ] **Check for any ERROR entries**
  ```bash
  grep -i "ERROR" logs/tts_server.log
  ```
  - Should be minimal or none
  - **Note any errors you see**

### Phase 7: Server Management

- [ ] **Stop server**
  ```bash
  ./stop.sh
  ```
  - Should show: `Server stopped`

- [ ] **Verify server stopped**
  ```bash
  ps aux | grep app.py
  ```
  - Should not show running process

- [ ] **Restart server**
  ```bash
  ./start.sh
  ```
  - Should start successfully again

- [ ] **Test health after restart**
  ```bash
  curl http://localhost:8080/health
  ```
  - Should return healthy status

### Phase 8: Stress Test (Optional)

- [ ] **Test multiple concurrent requests**
  ```bash
  for i in {1..5}; do
    curl -X POST "http://localhost:8080/tts" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"Test number $i\", \"speed\": 1.0}" \
      --output "test_$i.wav" &
  done
  wait
  ```
  - All 5 files should be created
  - No errors in logs

- [ ] **Test different speeds**
  ```bash
  for speed in 0.8 1.0 1.2 1.5; do
    curl -X POST "http://localhost:8080/tts" \
      -H "Content-Type: application/json" \
      -d "{\"text\": \"Speed test\", \"speed\": $speed}" \
      --output "speed_${speed}.wav"
  done
  ```
  - All files should be created successfully

## Results Summary

### ✅ Success Criteria (ALL must pass)

- [ ] setup.sh completes without errors
- [ ] All verification tests show "OK"
- [ ] start.sh starts server successfully  
- [ ] Health endpoint returns `"status": "healthy"`
- [ ] TTS synthesis creates valid audio files
- [ ] No "libmecab.so.2" errors in logs
- [ ] Server can be stopped and restarted

### ❌ Failure Indicators (ANY means fix failed)

- [ ] setup.sh shows "libmecab.so.2 FAILED" in verification
- [ ] start.sh shows "ERROR: libmecab.so.2 not found"
- [ ] Health endpoint returns `"status": "not_ready"`
- [ ] TTS requests fail with 500/503 errors
- [ ] Logs show "libmecab.so.2: cannot open shared object file"

## Reporting Results

### If Test PASSED ✅
Document:
- OS version: `cat /etc/os-release`
- GPU info (if applicable): `nvidia-smi`
- Setup time: How long did setup.sh take?
- First synthesis time: Check logs for timing
- Any warnings during setup (even if not fatal)

### If Test FAILED ❌
Collect this information:

```bash
# OS info
cat /etc/os-release

# Mecab package status
dpkg -l | grep mecab

# Library cache
ldconfig -p | grep libmecab

# Find library files
find /usr/lib /usr/local/lib -name "*mecab*" 2>/dev/null

# Python test
source venv/bin/activate
python3 -c "import ctypes; ctypes.CDLL('libmecab.so.2')" 2>&1

# Full logs
cat logs/tts_server.log

# Setup output
sudo ./setup.sh 2>&1 | tee setup_output.log
```

Then check `TROUBLESHOOTING.md` for manual fixes.

## Quick Commands Reference

```bash
# Start server
./start.sh

# Stop server
./stop.sh

# Restart server
./stop.sh && ./start.sh

# View logs (real-time)
tail -f logs/tts_server.log

# Check if running
ps aux | grep app.py
lsof -i :8080

# Test health
curl http://localhost:8080/health

# Test TTS
curl -X POST "http://localhost:8080/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test", "speed": 1.0}' \
  --output test.wav
```

## Documentation References

- **FRESH_INSTANCE_SETUP.md** - Detailed setup guide
- **TROUBLESHOOTING.md** - Fix for common issues
- **FIX_SUMMARY.md** - Technical details of the fix
- **CHANGES.md** - What was changed

---

**Test Version**: 1.0  
**Last Updated**: 2025-11-07  
**Expected Time**: ~5-10 minutes for complete test
