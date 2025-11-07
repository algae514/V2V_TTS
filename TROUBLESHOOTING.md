# Troubleshooting Guide - V2V_TTS Server

This guide covers common issues and their solutions when deploying the V2V_TTS server on fresh instances.

## Table of Contents
- [libmecab.so.2: Cannot Open Shared Object File](#libmecabso2-cannot-open-shared-object-file)
- [Server Fails to Start](#server-fails-to-start)
- [GPU Not Detected](#gpu-not-detected)
- [Port Already in Use](#port-already-in-use)
- [Python Package Installation Errors](#python-package-installation-errors)

---

## libmecab.so.2: Cannot Open Shared Object File

### Symptom
```
ERROR - [TTS] Failed to load MeloTTS model on cuda: libmecab.so.2: cannot open shared object file: No such file or directory
ERROR - [TTS] CPU fallback also failed: libmecab.so.2: cannot open shared object file: No such file or directory
```

### Root Cause
The `libmecab.so.2` shared library is required by MeloTTS for Japanese text processing but is not found in the system's library cache. This happens on fresh server instances where:
1. The library is installed but not properly registered in the dynamic linker cache
2. The library path is not included in `LD_LIBRARY_PATH`
3. The system's library cache wasn't refreshed after installation

### Solution (Automatic - Already in setup.sh v2)
The updated `setup.sh` now automatically:
1. Installs mecab packages (`libmecab2`, `mecab`, `libmecab-dev`)
2. Runs `ldconfig` to refresh the library cache
3. Verifies `libmecab.so.2` is available
4. Attempts to locate and link the library if not found
5. Tests the library can be loaded by Python

The updated `start.sh` now:
1. Sets `LD_LIBRARY_PATH` to include common library directories
2. Performs a pre-flight check to verify mecab is loadable
3. Provides clear error messages with fix instructions if mecab is missing

### Manual Fix (If Automatic Fix Fails)

#### Step 1: Verify mecab packages are installed
```bash
dpkg -l | grep mecab
```

You should see:
- `libmecab2` - Runtime library
- `mecab` - Main package
- `libmecab-dev` - Development files
- `mecab-ipadic-utf8` - Dictionary

If missing, install them:
```bash
sudo apt-get update
sudo apt-get install -y mecab libmecab2 libmecab-dev mecab-ipadic-utf8
```

#### Step 2: Refresh library cache
```bash
sudo ldconfig
```

#### Step 3: Verify library is in cache
```bash
ldconfig -p | grep libmecab
```

You should see output like:
```
libmecab.so.2 (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/libmecab.so.2
libmecab.so (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/libmecab.so
```

#### Step 4: If not found, locate and link manually
```bash
# Find the library
find /usr/lib /usr/local/lib -name "libmecab.so.2*" 2>/dev/null

# If found (e.g., at /usr/lib/x86_64-linux-gnu/libmecab.so.2)
# Add its directory to ld.so.conf
echo "/usr/lib/x86_64-linux-gnu" | sudo tee /etc/ld.so.conf.d/mecab.conf
sudo ldconfig
```

#### Step 5: Set LD_LIBRARY_PATH (if still not working)
Add to your `~/.bashrc` or set before starting:
```bash
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/local/lib:${LD_LIBRARY_PATH}
```

#### Step 6: Test the library
```bash
python3 -c "import ctypes; ctypes.CDLL('libmecab.so.2')"
```

No output = success. Error = library still not found.

#### Step 7: Restart the server
```bash
./stop.sh  # If already running
./start.sh
```

---

## Server Fails to Start

### Check Logs
```bash
tail -f logs/tts_server.log
```

### Common Causes

#### 1. Missing Python Packages
**Symptom**: `ModuleNotFoundError: No module named 'xxx'`

**Solution**:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

#### 2. PyTorch/CUDA Issues
**Symptom**: `RuntimeError: CUDA out of memory` or `torch not found`

**Solution**:
```bash
source venv/bin/activate
# For GPU (CUDA 11.8)
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu118
# For CPU only
pip install torch torchaudio
```

#### 3. Port Already in Use
**Symptom**: `OSError: [Errno 98] Address already in use`

**Solution**:
```bash
# Find process using port 8080
lsof -i :8080
# Kill it
kill -9 <PID>
# Or let start.sh handle it (it auto-kills port occupants)
./start.sh
```

---

## GPU Not Detected

### Check GPU Availability
```bash
nvidia-smi
```

If this fails, GPU drivers are not installed.

### Verify PyTorch Can See GPU
```bash
source venv/bin/activate
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"
```

### Force CPU Mode
If GPU isn't working, you can force CPU mode:
```bash
export TTS_DEVICE=cpu
./start.sh
```

### Reinstall PyTorch with CUDA Support
```bash
source venv/bin/activate
pip uninstall torch torchaudio
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu118
```

---

## Port Already in Use

### Automatic Fix
The `start.sh` script automatically kills processes on port 8080.

### Manual Fix
```bash
# Find process
lsof -i :8080
# Kill it
kill -9 <PID>
```

### Use Different Port
```bash
PORT=9000 ./start.sh
```

---

## Python Package Installation Errors

### tokenizers Build Fails
**Symptom**: `error: failed to compile tokenizers`

**Solution**: Install Rust compiler
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
# Then re-run setup
./setup.sh
```

### mecab-python3 Build Fails
**Symptom**: `error: command 'gcc' failed`

**Solution**: Install build dependencies
```bash
sudo apt-get install -y build-essential python3-dev libmecab-dev
```

### transformers Version Conflicts
**Symptom**: `ERROR: pip's dependency resolver does not currently take into account all the packages`

**Solution**: Use `--no-deps` flag (already in setup.sh)
```bash
pip install --no-deps git+https://github.com/myshell-ai/MeloTTS.git@main
```

---

## Fresh Server Instance Setup - Complete Process

When starting from a **completely fresh server instance**, follow this exact sequence:

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd V2V_TTS
```

### 2. Run Setup (This handles everything)
```bash
chmod +x setup.sh start.sh stop.sh
sudo ./setup.sh
```

The setup script will:
- ✅ Update system packages
- ✅ Install system dependencies (mecab, ffmpeg, sox, etc.)
- ✅ Configure mecab library paths
- ✅ Install Rust compiler
- ✅ Create Python virtual environment
- ✅ Install PyTorch with GPU support
- ✅ Install all Python dependencies
- ✅ Install MeloTTS
- ✅ Download UniDic dictionary
- ✅ Verify all installations

### 3. Check Verification Results
At the end of setup, you'll see:
```
[VERIFICATION] Testing installation...
Checking libmecab.so.2... OK
Checking PyTorch installation... OK
Checking MeloTTS installation... OK
```

If any check fails, refer to the specific section above.

### 4. Start Server
```bash
./start.sh
```

### 5. Verify Server is Running
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

### 6. Test TTS
```bash
curl -X POST "http://localhost:8080/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, this is a test", "speed": 1.0}' \
  --output test.wav
```

---

## Debug Mode

### Enable Verbose Logging
Edit `app.py` and change:
```python
logging.basicConfig(level=logging.DEBUG, ...)
```

### Run Server in Foreground
```bash
source venv/bin/activate
python3 app.py
```

This shows all logs in real-time.

---

## Still Having Issues?

### Collect Debug Information
```bash
# System info
uname -a
cat /etc/os-release

# GPU info
nvidia-smi

# Library info
ldconfig -p | grep libmecab
ldd $(which mecab)

# Python environment
source venv/bin/activate
pip list | grep -E "torch|melo|transformers|mecab"
python3 -c "import sys; print(sys.version)"

# Server logs
tail -50 logs/tts_server.log
```

### Common Environment Issues

#### Running as Non-Root User
If you're not root, some commands need `sudo`:
```bash
sudo ldconfig
sudo apt-get install ...
```

#### SELinux/AppArmor Restrictions
On some systems, security policies may block library loading:
```bash
# Check SELinux status
getenforce
# If enforcing, try permissive mode (temporary)
sudo setenforce 0
```

#### Older Linux Distributions
If using Ubuntu < 20.04 or Debian < 11:
- Update to a newer version for better compatibility
- Or manually compile mecab from source

---

## Prevention Checklist

Before deploying to a fresh instance:

- [ ] Ensure you have root/sudo access
- [ ] Verify internet connectivity for package downloads
- [ ] Check available disk space (>10GB recommended)
- [ ] Verify GPU drivers if using GPU
- [ ] Run `./setup.sh` with sudo privileges
- [ ] Check verification output at end of setup
- [ ] Test server startup with `./start.sh`
- [ ] Verify health endpoint responds
- [ ] Test actual TTS synthesis

---

## Contact & Support

If you encounter an issue not covered here:
1. Check the logs: `tail -f logs/tts_server.log`
2. Run verification: `python3 -c "import ctypes; ctypes.CDLL('libmecab.so.2')"`
3. Review this troubleshooting guide
4. Check GitHub issues (if applicable)

---

**Last Updated**: 2025-11-07  
**Version**: 2.0 (with libmecab.so.2 fix)
