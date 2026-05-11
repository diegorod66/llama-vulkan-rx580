#!/bin/bash
# llama-vulkan-rx580 :: uninstall.sh :: v2.0.0
# Desinstalacion completa de llama-server
# Uso: sudo ./deploy/uninstall.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root (sudo)."
    exit 1
fi

echo "=== llama-vulkan-rx580 :: Uninstall ==="
echo ""

# Stop and disable service
echo "[1/4] Stopping service..."
systemctl stop llama-server 2>/dev/null || true
systemctl disable llama-server 2>/dev/null || true

# Remove service file
echo "[2/4] Removing service files..."
rm -f /etc/systemd/system/llama-server.service
systemctl daemon-reload

# Remove binaries
echo "[3/4] Removing binaries..."
rm -f /usr/local/bin/llama-server
rm -f /usr/local/lib/libllama*.so*
rm -f /usr/local/lib/libggml*.so*
rm -f /usr/local/lib/libmtmd*.so*
ldconfig

# Remove config
echo "[4/4] Removing config..."
rm -rf /etc/llama-server

# Remove user (optional)
if id "llama" &>/dev/null; then
    userdel llama 2>/dev/null || echo "  (llama user kept - in use by other process)"
fi

echo ""
echo "=== Uninstall complete ==="
