#!/bin/bash

# Test script for TTS Server

set -e

BASE_URL="${1:-http://localhost:8080}"

echo "🧪 Testing TTS Server at: $BASE_URL"
echo ""

# Test 1: Health check
echo "Test 1: Health Check"
curl -s "$BASE_URL/health" | jq .
echo ""

# Test 2: Root endpoint
echo "Test 2: Root Endpoint"
curl -s "$BASE_URL/" | jq .
echo ""

# Test 3: Simple synthesis
echo "Test 3: Simple Synthesis"
echo "Request: Synthesizing 'Hello, this is a test'"
curl -X POST "$BASE_URL/tts_simple?text=Hello%2C%20this%20is%20a%20test" \
    -o /tmp/test_output.wav
echo "Audio saved to /tmp/test_output.wav"
echo ""

# Test 4: JSON synthesis
echo "Test 4: JSON Synthesis"
curl -X POST "$BASE_URL/tts" \
    -H "Content-Type: application/json" \
    -d '{"text": "This is a JSON request test"}' \
    -o /tmp/test_output_json.wav
echo "Audio saved to /tmp/test_output_json.wav"
echo ""

# Test 5: List models
echo "Test 5: List Models"
curl -s "$BASE_URL/models" | jq .
echo ""

echo "✅ All tests completed!"
echo ""
echo "To play the audio files:"
echo "  ffplay /tmp/test_output.wav"
echo "  ffplay /tmp/test_output_json.wav"

