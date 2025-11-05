# Model Information & Dependencies

## 🎤 Model Being Used

**Model:** MeloTTS English (default model from MeloTTS library)

**Source:** 
- Repository: `https://github.com/myshell-ai/MeloTTS.git`
- Branch: `main` (latest)
- Installation: `git+https://github.com/myshell-ai/MeloTTS.git@main`

**Initialization:**
```python
from melo.api import TTS
self.model = TTS(language="EN", device=self.device)
```

**Model Details:**
- Language: English ("EN")
- Sample Rate: 44100 Hz
- Device: Auto-detects CUDA/GPU, falls back to CPU
- Version: Latest from main branch (model version determined by MeloTTS library)

**Note:** The code uses the default English model provided by MeloTTS. The actual model version (v3, v4, etc.) depends on what's in the MeloTTS repository's main branch at installation time.

## 📦 Dependencies Verification

### Core Dependencies (requirements.txt)
- ✅ `fastapi==0.104.1` - Web framework
- ✅ `uvicorn[standard]==0.24.0` - ASGI server
- ✅ `pydantic==2.5.0` - Data validation
- ✅ `python-multipart==0.0.6` - Form data handling
- ✅ `soundfile==0.12.1` - Audio file I/O
- ✅ `numpy>=1.26.0` - Numerical operations (note: minimum version)
- ✅ `requests==2.31.0` - HTTP client
- ✅ `hf_transfer` - Hugging Face model transfer (optional, for MeloTTS)
- ✅ `soxr` - Audio resampling (optional, for MeloTTS)

### PyTorch (installed separately in setup.sh)
- ✅ `torch` - Deep learning framework
- ✅ `torchaudio` - Audio processing
- **Installation:** Done in `setup.sh` with GPU detection:
  - GPU available: CUDA 11.8 version
  - CPU only: Standard PyTorch

### MeloTTS Dependencies
- ✅ Installed via `git+https://github.com/myshell-ai/MeloTTS.git@main`
- Includes all sub-dependencies (MeCab, transformers, etc.)
- UniDic dictionary downloaded separately via `python3 -m unidic download`

## ✅ Verification Status

### Code Implementation
- ✅ Model initialization: Correctly uses `TTS(language="EN")`
- ✅ GPU detection: Auto-detects CUDA, falls back to CPU
- ✅ Error handling: Proper fallback mechanism
- ✅ Sample rate: Correctly set to 44100 Hz

### Setup Script (setup.sh)
- ✅ System dependencies: MeCab, ffmpeg, etc. installed
- ✅ PyTorch installation: GPU-aware installation
- ✅ MeloTTS installation: From git repository
- ✅ UniDic dictionary: Download handled

### Requirements (requirements.txt)
- ✅ All dependencies listed
- ✅ PyTorch correctly excluded (installed separately)
- ✅ Comment updated to reflect setup.sh installation

### Documentation
- ✅ README.md mentions "MeloTTS-English v3"
- ⚠️ Note: Actual version depends on MeloTTS main branch
- ✅ Model details documented in API responses

## 🔍 Recommendations

1. **Model Version Pinning:** Consider pinning to a specific MeloTTS commit/tag if you need reproducible builds:
   ```
   git+https://github.com/myshell-ai/MeloTTS.git@<commit-hash>
   ```

2. **Numpy Version:** Current `>=1.26.0` should work, but if issues arise, consider pinning to `1.26.0` or `1.24.3`

3. **Documentation:** Consider adding model version to `/models` endpoint response for better tracking

## 📝 Summary

**Model:** MeloTTS English (default from main branch)  
**Status:** ✅ Properly configured  
**Dependencies:** ✅ All correct and documented  
**Setup:** ✅ Handles GPU/CPU correctly  
**Documentation:** ✅ Accurate (with minor note about version)

