#!/bin/bash
# llama-vulkan-rx580 :: quick-test.sh :: v2.0.0
# Prueba rapida del servidor llama-server
# Uso: ./examples/quick-test.sh [host:port]

set -euo pipefail

HOST="${1:-localhost:11434}"
BASE_URL="http://$HOST"
MODEL="${MODEL:-model}"

echo "=== llama-server Quick Test ==="
echo "Server: $BASE_URL"
echo "Model:  $MODEL"
echo ""

# 1. Health check
echo "[1/3] Health check..."
if curl -sf "$BASE_URL/health" > /dev/null 2>&1; then
    echo "  OK - Server is running"
else
    echo "  WARNING: Health check failed (may not be supported)"
fi

# 2. List models
echo "[2/3] Listing models..."
curl -sf "$BASE_URL/v1/models" | python3 -m json.tool 2>/dev/null || \
    curl -sf "$BASE_URL/v1/models" || echo "  (no models endpoint)"

# 3. Chat completion test
echo "[3/3] Chat completion test..."
curl -s -X POST "$BASE_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "'"$MODEL"'",
        "messages": [{"role": "user", "content": "Responde solo: hola mundo"}],
        "max_tokens": 20,
        "temperature": 0
    }' | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    content = data['choices'][0]['message']['content']
    print(f'  Response: {content}')
    print(f'  Tokens: {data[\"usage\"]}')
except Exception as e:
    print(f'  Raw: {sys.stdin.read()}')
" 2>/dev/null || echo "  (parse fallback)"

echo ""
echo "=== Test complete ==="
