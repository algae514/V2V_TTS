"""
Example Python client for TTS Server
"""

import requests
import argparse


def synthesize_text(server_url: str, text: str, output_file: str = "output.wav"):
    """
    Synthesize text to speech
    
    Args:
        server_url: Base URL of the TTS server
        text: Text to synthesize
        output_file: Output file path
    
    Returns:
        True if successful
    """
    try:
        print(f"Synthesizing: {text}")
        
        # Make request
        response = requests.post(
            f"{server_url}/tts_simple",
            params={"text": text},
            timeout=60
        )
        
        # Check status
        response.raise_for_status()
        
        # Save audio
        with open(output_file, "wb") as f:
            f.write(response.content)
        
        print(f"✅ Audio saved to: {output_file}")
        return True
    
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def synthesize_json(server_url: str, text: str, output_file: str = "output.wav"):
    """
    Synthesize using JSON endpoint (supports advanced options)
    
    Args:
        server_url: Base URL of the TTS server
        text: Text to synthesize
        output_file: Output file path
    
    Returns:
        True if successful
    """
    try:
        print(f"Synthesizing (JSON): {text}")
        
        response = requests.post(
            f"{server_url}/tts",
            json={"text": text},
            timeout=60
        )
        
        response.raise_for_status()
        
        with open(output_file, "wb") as f:
            f.write(response.content)
        
        print(f"✅ Audio saved to: {output_file}")
        return True
    
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def check_health(server_url: str):
    """Check server health"""
    try:
        response = requests.get(f"{server_url}/health")
        print(f"Health Status: {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="TTS Server Client")
    parser.add_argument("--url", default="http://localhost:8080", help="Server URL")
    parser.add_argument("--text", required=True, help="Text to synthesize")
    parser.add_argument("--output", default="output.wav", help="Output file")
    parser.add_argument("--health", action="store_true", help="Check server health")
    
    args = parser.parse_args()
    
    if args.health:
        check_health(args.url)
    else:
        synthesize_text(args.url, args.text, args.output)


if __name__ == "__main__":
    main()

