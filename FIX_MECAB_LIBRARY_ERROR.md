# Fix: mecab Library Error

## When to Use This

**You see this error:**
```
ERROR: libmecab.so.2 not found!
```

**Or server won't start after setup.sh completed**

---

## The Fix (Copy-Paste These Commands)

Run these commands **as root** (or with sudo):

```bash
# Step 1: Install mecab packages
apt-get update
apt-get install -y mecab libmecab2 libmecab-dev mecab-ipadic-utf8

# Step 2: Configure library cache
echo "/usr/lib/x86_64-linux-gnu" > /etc/ld.so.conf.d/mecab.conf
ldconfig
sleep 2

# Step 3: Verify mecab is installed
ldconfig -p | grep libmecab
```

**Expected output from Step 3:**
```
libmecab.so.2 (libc6,x86-64) => /usr/lib/x86_64-linux-gnu/libmecab.so.2.0.0
```

If you see that line, mecab is fixed. ✅

---

## Start the Server

```bash
cd /workspace/V2V_TTS
./start.sh
```

---

## Verify It's Working

```bash
curl http://localhost:8080/health
```

**Expected response:**
```json
{"status":"healthy","model_loaded":true,"device":"cuda","tts_engine":"MeloTTS"}
```

---

## Alternative: Use the Quick Fix Script

```bash
cd /workspace/V2V_TTS
./quick_fix.sh
./start.sh
```

The `quick_fix.sh` script does all the steps above automatically.

---

## Why This Happens

The setup script installs mecab packages, but sometimes the library cache (`ldconfig`) doesn't update properly on fresh cloud instances. This fix manually ensures mecab is installed and the library cache is refreshed.

---

## Still Not Working?

Check these:

1. **Are you root?**
   ```bash
   whoami
   # Should show: root
   ```

2. **Is mecab actually installed?**
   ```bash
   dpkg -l | grep mecab
   ```
   Should show multiple mecab packages.

3. **Can Python find the library?**
   ```bash
   cd /workspace/V2V_TTS
   source venv/bin/activate
   export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
   python3 -c "import ctypes; ctypes.CDLL('libmecab.so.2')"
   ```
   Should produce no output (success).

If any of these fail, re-run the fix commands above.
