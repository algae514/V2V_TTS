# Troubleshooting Guide

## Setup Issues

### Issue: Server won't start - "libmecab.so.2 not found"

**Symptoms:**
- `./start.sh` fails with "ERROR: libmecab.so.2 not found!"
- Server process won't run
- Health endpoint doesn't respond

**Cause:**
The mecab system library wasn't properly installed or configured during setup.

**Solution:**
Run the quick fix script:
```bash
./quick_fix.sh
```

Or manually:
```bash
# Install mecab packages
apt-get update
apt-get install -y mecab libmecab2 libmecab-dev mecab-ipadic-utf8

# Configure library cache
echo "/usr/lib/x86_64-linux-gnu" > /etc/ld.so.conf.d/mecab.conf
ldconfig

# Verify
ldconfig -p | grep libmecab
```

Then start the server:
```bash
./start.sh
```

---

### Issue: pip dependency warning about transformers version

**Symptoms:**
During setup, you see:
```
melotts 0.1.2 has requirement transformers==4.27.4, but you have transformers 4.57.1
```

**Solution:**
**This is harmless.** MeloTTS specifies an older transformers version, but the newer version works perfectly. You can safely ignore this warning. The server will run fine.

---

### Issue: Server starts but doesn't respond

**Check these:**
1. Is the process running?
   ```bash
   ps aux | grep python
   ```

2. Is the port listening?
   ```bash
   ss -tulpn | grep 8080
   ```

3. Check the logs:
   ```bash
   tail -f logs/tts_server.log
   ```

4. Test the health endpoint:
   ```bash
   curl http://localhost:8080/health
   ```

---

## Fresh Instance Setup

For a completely fresh instance, run in this order:

```bash
# 1. Run setup (installs everything)
./setup.sh

# 2. Start the server
./start.sh

# 3. Test it works
curl http://localhost:8080/health
```

Setup should complete with:
```
✅ Setup complete!
```

If setup fails with errors, **do not proceed to start.sh**. Fix the errors first.

---

## Getting Help

If you encounter issues:

1. Check what failed during setup:
   - Look for RED error messages in setup output
   - Check if all verification tests passed

2. Provide these details:
   - Output of `./setup.sh` (especially errors)
   - Output of `./start.sh`
   - Content of `logs/tts_server.log`
   - Output of `dpkg -l | grep mecab`
