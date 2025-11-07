"""
TTS Server for Vast.ai Deployment
FastAPI-based Text-to-Speech service using MeloTTS
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional
from contextlib import asynccontextmanager
import os
import uuid
import logging
import numpy as np
import torch
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('tts_server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global TTS instance
melotts = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events"""
    # Startup
    initialize_tts()
    yield
    # Shutdown (cleanup if needed)
    logger.info("Shutting down TTS server...")


app = FastAPI(title="TTS Server (MeloTTS)", version="2.0.0", lifespan=lifespan)

class TTSRequest(BaseModel):
    text: str
    speed: Optional[float] = 1.0
    language: Optional[str] = "EN"


class MeloTTS:
    """MeloTTS-English v3 text-to-speech synthesis with streaming support and GPU acceleration."""
    
    def __init__(self, device: str = None, language: str = "EN"):
        """
        Initialize MeloTTS model with automatic GPU detection.
        
        Args:
            device: Device to run on ('cpu' or 'cuda', auto-detects if None)
            language: Language code ('EN' for English)
        """
        # Auto-detect GPU availability
        if device is None:
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
            logger.info(f"[TTS] Auto-detected device: {self.device}")
        else:
            self.device = device
        
        self.language = language
        self.model = None
        self.speaker_id = None
        self.sample_rate = 44100  # MeloTTS actual sample rate
        self.is_ready_flag = False
    
    def initialize_model(self):
        """Initialize the MeloTTS model with GPU support."""
        try:
            # Import MeloTTS here to avoid blocking startup
            from melo.api import TTS
            
            logger.info(f"[TTS] Loading MeloTTS-English model on {self.device}...")
            start_time = time.time()
            
            # Show GPU info if available
            if self.device == "cuda" and torch.cuda.is_available():
                gpu_name = torch.cuda.get_device_name(0)
                gpu_memory = torch.cuda.get_device_properties(0).total_memory / 1024**3
                logger.info(f"[TTS] GPU detected: {gpu_name} ({gpu_memory:.2f} GB)")
            
            self.model = TTS(language=self.language, device=self.device)
            
            # Get speaker IDs and use first available English speaker
            speaker_ids = self.model.hps.data.spk2id
            if speaker_ids:
                self.speaker_id = list(speaker_ids.values())[0]
                logger.info(f"[TTS] Using speaker ID: {self.speaker_id}")
            else:
                raise ValueError("No speakers available in MeloTTS model")
            
            elapsed = time.time() - start_time
            logger.info(f"[TTS] MeloTTS model loaded on {self.device} in {elapsed:.2f}s")
            self.is_ready_flag = True
            
        except Exception as e:
            logger.error(f"[TTS] Failed to load MeloTTS model on {self.device}: {e}")
            
            # Fallback to CPU if GPU fails
            if self.device == "cuda":
                logger.warning("[TTS] Falling back to CPU...")
                self.device = "cpu"
                try:
                    from melo.api import TTS
                    self.model = TTS(language=self.language, device=self.device)
                    speaker_ids = self.model.hps.data.spk2id
                    if speaker_ids:
                        self.speaker_id = list(speaker_ids.values())[0]
                    logger.info(f"[TTS] MeloTTS model loaded on CPU (fallback)")
                    self.is_ready_flag = True
                except Exception as e2:
                    logger.error(f"[TTS] CPU fallback also failed: {e2}")
                    self.is_ready_flag = False
            else:
                self.is_ready_flag = False
    
    def is_ready(self) -> bool:
        """Check if TTS model is ready."""
        return self.is_ready_flag and self.model is not None
    
    def synthesize_to_file(self, text: str, output_path: str, speed: float = 1.0):
        """
        Synthesize text to audio file.
        
        Args:
            text: Text to synthesize
            output_path: Output file path
            speed: Speech speed
        """
        try:
            logger.info(f"[TTS] Synthesizing: '{text[:50]}{'...' if len(text) > 50 else ''}'")
            start_time = time.time()
            
            # Generate audio file
            self.model.tts_to_file(
                text=text,
                speaker_id=self.speaker_id,
                output_path=output_path,
                speed=speed
            )
            
            elapsed = time.time() - start_time
            logger.info(f"[TTS] Synthesis completed in {elapsed:.2f}s")
            
        except Exception as e:
            logger.error(f"[TTS] Synthesis error: {e}")
            raise
    
    def get_sample_rate(self) -> int:
        """Get the sample rate of synthesized audio."""
        return self.sample_rate
    
    def get_device(self) -> str:
        """Get the device being used."""
        return self.device


def initialize_tts():
    """Initialize the MeloTTS model"""
    global melotts
    try:
        # Download required NLTK data
        try:
            import nltk
            nltk.download('averaged_perceptron_tagger_eng', quiet=True)
        except Exception as e:
            logger.warning(f"Failed to download NLTK data: {e}")
        
        logger.info("Initializing MeloTTS model...")
        device = os.getenv("TTS_DEVICE", None)
        language = os.getenv("TTS_LANGUAGE", "EN")
        
        melotts = MeloTTS(device=device, language=language)
        melotts.initialize_model()
        
        if melotts.is_ready():
            logger.info("✅ MeloTTS model loaded successfully!")
        else:
            logger.error("❌ Failed to initialize MeloTTS model")
            raise RuntimeError("TTS model initialization failed")
        
    except Exception as e:
        logger.error(f"Error initializing TTS: {e}")
        raise


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "online",
        "service": "Text-to-Speech Server (MeloTTS)",
        "version": "2.0.0",
        "model": "MeloTTS-English",
        "ready": melotts.is_ready() if melotts else False
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    device = melotts.get_device() if melotts and melotts.is_ready() else "unknown"
    ready = melotts.is_ready() if melotts else False
    return {
        "status": "healthy" if ready else "not_ready",
        "model_loaded": ready,
        "device": device,
        "tts_engine": "MeloTTS"
    }


@app.post("/tts")
async def synthesize(request: TTSRequest):
    """
    Synthesize speech from text using MeloTTS
    
    Args:
        text: The text to synthesize
        speed: Speech speed (default: 1.0)
        language: Optional language code (default: EN)
    
    Returns:
        Audio file (WAV)
    """
    if not melotts or not melotts.is_ready():
        raise HTTPException(status_code=503, detail="TTS model not initialized")
    
    if not request.text or not request.text.strip():
        raise HTTPException(status_code=400, detail="Text cannot be empty")
    
    try:
        # Generate unique filename
        audio_id = str(uuid.uuid4())
        output_path = f"/tmp/{audio_id}.wav"
        
        logger.info(f"Synthesizing text (speed={request.speed}): {request.text[:100]}")
        
        # Synthesize speech with MeloTTS
        melotts.synthesize_to_file(
            text=request.text,
            output_path=output_path,
            speed=request.speed
        )
        
        logger.info(f"✅ Audio generated: {output_path}")
        
        # Return audio file
        return FileResponse(
            output_path,
            media_type="audio/wav",
            filename=f"{audio_id}.wav",
            background=BackgroundTasks().add_task(cleanup_file, output_path)
        )
    
    except Exception as e:
        logger.error(f"❌ Error synthesizing speech: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/tts_simple")
async def synthesize_simple(
    text: str,
    speed: float = 1.0
):
    """
    Simple synthesis endpoint (no JSON body required)
    
    Args:
        text: The text to synthesize
        speed: Speech speed (default: 1.0)
    
    Returns:
        Audio file (WAV)
    """
    request = TTSRequest(text=text, speed=speed)
    return await synthesize(request)


@app.get("/models")
async def list_models():
    """List available TTS models and status"""
    if not melotts:
        return {"error": "TTS not initialized"}
    
    return {
        "model": "MeloTTS-English",
        "device": melotts.get_device() if melotts.is_ready() else "unknown",
        "sample_rate": melotts.get_sample_rate(),
        "ready": melotts.is_ready(),
        "language": melotts.language
    }


def cleanup_file(file_path: str):
    """Clean up temporary file after serving"""
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            logger.info(f"Cleaned up: {file_path}")
    except Exception as e:
        logger.error(f"Error cleaning up file {file_path}: {e}")


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8080"))
    uvicorn.run(app, host="0.0.0.0", port=port)

