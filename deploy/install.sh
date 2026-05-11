#!/bin/bash
# llama-vulkan-rx580 :: install.sh :: v2.0.0
# Instalador automatizado: detecta GPUs Vulkan, copia binarios,
# calcula parámetros óptimos y configura el servicio systemd.
#
# Uso: sudo ./deploy/install.sh
#   -v, --version VERSION   Especifica versión a instalar (v1.0.0 o v2.0.0)
#   -m, --model PATH        Ruta al modelo .gguf
#   -p, --port PORT         Puerto del servidor (default: 11434)
#   --uninstall             Elimina la instalación

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib"
SERVICE_FILE="/etc/systemd/system/llama-server.service"
ENV_FILE="/etc/llama-server/llama-server.env"
LLAMA_USER="llama"

# --- Parse arguments ---
INSTALL_VERSION=""
MODEL_PATH=""
PORT="11434"
DO_UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version) INSTALL_VERSION="$2"; shift 2 ;;
        -m|--model) MODEL_PATH="$2"; shift 2 ;;
        -p|--port) PORT="$2"; shift 2 ;;
        --uninstall) DO_UNINSTALL=true; shift ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# --- Uninstall mode ---
if [ "$DO_UNINSTALL" = true ]; then
    echo -e "${YELLOW}[!] Uninstalling llama-server...${NC}"
    systemctl stop llama-server 2>/dev/null || true
    systemctl disable llama-server 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    rm -f "$BIN_DIR/llama-server"
    rm -f "$LIB_DIR"/libllama*.so*
    rm -f "$LIB_DIR"/libggml*.so*
    rm -f "$LIB_DIR"/libmtmd*.so*
    ldconfig
    rm -rf /etc/llama-server
    userdel "$LLAMA_USER" 2>/dev/null || true
    echo -e "${GREEN}[✓] Uninstall complete.${NC}"
    exit 0
fi

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   llama-vulkan-rx580 :: Installer v2.0.0 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# --- Ensure root ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Please run as root (sudo).${NC}"
    exit 1
fi

# --- 1. Detect version to install ---
echo -e "${YELLOW}[1/7] Detecting version...${NC}"
if [ -z "$INSTALL_VERSION" ]; then
    # Try v2.0.0 first, fallback to v1.0.0
    if [ -d "$SCRIPT_DIR/binaries-v2.0.0" ] && ls "$SCRIPT_DIR/binaries-v2.0.0"/llama-server* &>/dev/null; then
        INSTALL_VERSION="v2.0.0"
    elif [ -d "$SCRIPT_DIR/binaries-v1.0.0" ] && ls "$SCRIPT_DIR/binaries-v1.0.0"/llama-server* &>/dev/null; then
        INSTALL_VERSION="v1.0.0"
    else
        echo -e "${RED}ERROR: No binaries found. Run scripts/build.sh first or download from GitHub Actions.${NC}"
        exit 1
    fi
fi
echo "  Version: $INSTALL_VERSION"

# --- 2. Check prerequisites ---
echo -e "${YELLOW}[2/7] Checking prerequisites...${NC}"
for cmd in vulkaninfo systemctl curl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}ERROR: $cmd not found. Install vulkan-tools, systemd, curl.${NC}"
        exit 1
    fi
done
echo "  All prerequisites found."

# --- 3. Detect GPUs ---
echo -e "${YELLOW}[3/7] Detecting Vulkan GPUs...${NC}"
GPU_COUNT=0
GPU_NAMES=()
while IFS= read -r line; do
    if echo "$line" | grep -qi "deviceName\|Device Name\|GPU[0-9]"; then
        GPU_COUNT=$((GPU_COUNT + 1))
        GPU_NAMES+=("$line")
    fi
done < <(vulkaninfo --summary 2>/dev/null || echo "WARNING: vulkaninfo failed")

if [ "$GPU_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}  WARNING: No Vulkan devices detected via vulkaninfo.${NC}"
    echo "  Attempting fallback detection..."
    GPU_COUNT=$(ls -d /dev/dri/renderD* 2>/dev/null | wc -l)
    if [ "$GPU_COUNT" -gt 0 ]; then
        echo "  Found $GPU_COUNT render nodes (may include non-GPU devices)"
    else
        echo -e "${YELLOW}  No GPUs detected. Will install but service won't start until GPUs are present.${NC}"
    fi
fi

echo "  GPUs detected: $GPU_COUNT"
for gpu in "${GPU_NAMES[@]}"; do
    echo "    - $gpu"
done

# --- 4. Calculate optimal parameters ---
echo -e "${YELLOW}[4/7] Calculating optimal parameters...${NC}"

# VRAM estimation: assume 8GB per GPU (RX 580)
TOTAL_VRAM=$((GPU_COUNT * 8))
if [ "$TOTAL_VRAM" -eq 0 ]; then
    TOTAL_VRAM=8  # default fallback
fi

# ctx-size based on VRAM (conservative: ~1GB per 4096 tokens)
CTX_SIZE=$((TOTAL_VRAM * 512))
if [ "$CTX_SIZE" -gt 131072 ]; then
    CTX_SIZE=131072
fi

# Split mode
if [ "$GPU_COUNT" -ge 2 ]; then
    SPLIT_MODE="layer"
else
    SPLIT_MODE="none"
fi

echo "  Total VRAM (est.): ${TOTAL_VRAM} GB"
echo "  ctx-size:          ${CTX_SIZE}"
echo "  split-mode:        ${SPLIT_MODE}"

# --- 5. Copy binaries ---
echo -e "${YELLOW}[5/7] Installing binaries...${NC}"
BINARY_SRC="$SCRIPT_DIR/binaries-$INSTALL_VERSION"
mkdir -p "$BIN_DIR" "$LIB_DIR"

cp "$BINARY_SRC/llama-server" "$BIN_DIR/llama-server"
chmod 755 "$BIN_DIR/llama-server"

# Copy .so files
for lib in "$BINARY_SRC"/*.so*; do
    if [ -f "$lib" ]; then
        cp -a "$lib" "$LIB_DIR/"
    fi
done

ldconfig
echo "  llama-server -> $BIN_DIR/llama-server"
echo "  Libraries   -> $LIB_DIR/"

# --- 5b. Create llama user ---
id -u "$LLAMA_USER" &>/dev/null || useradd -r -s /bin/false "$LLAMA_USER"

# --- 6. Prompt for model path if not provided ---
echo -e "${YELLOW}[6/7] Configuring model...${NC}"
if [ -z "$MODEL_PATH" ]; then
    echo "  Enter path to your .gguf model file (or leave empty to edit later):"
    read -r MODEL_PATH
fi

# --- 7. Generate systemd service ---
echo -e "${YELLOW}[7/7] Generating systemd service...${NC}"

# Build GPU device list
if [ "$GPU_COUNT" -gt 0 ]; then
    VK_DEVICES=$(seq -s ',' 0 $((GPU_COUNT - 1)))
else
    VK_DEVICES="0"
fi

mkdir -p /etc/llama-server

# Write env file
cat > "$ENV_FILE" << EOF
# llama-vulkan-rx580 :: Configuracion
# Generado automaticamente por install.sh

GGML_VK_VISIBLE_DEVICES=$VK_DEVICES
LD_LIBRARY_PATH=$LIB_DIR
MODEL_PATH=$MODEL_PATH
PORT=$PORT
CTX_SIZE=$CTX_SIZE
SPLIT_MODE=$SPLIT_MODE
BATCH_SIZE=2048
NGL=99
EOF

# Write service file
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=llama-server (Vulkan $GPU_COUNT GPUs, version $INSTALL_VERSION)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$LLAMA_USER
EnvironmentFile=$ENV_FILE
ExecStart=$BIN_DIR/llama-server \\
  --model \${MODEL_PATH} \\
  --host 0.0.0.0 \\
  --port \${PORT} \\
  -ngl \${NGL} \\
  --split-mode \${SPLIT_MODE} \\
  --ctx-size \${CTX_SIZE} \\
  --batch-size \${BATCH_SIZE}
Restart=always
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
echo "  Service: $SERVICE_FILE"
echo "  Env:     $ENV_FILE"

# --- Summary ---
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Instalacion completada          ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════╣${NC}"
printf "${GREEN}║  ${NC}%-20s ${GREEN}%10s  ${GREEN}║${NC}\n" "Version:" "$INSTALL_VERSION"
printf "${GREEN}║  ${NC}%-20s ${GREEN}%10s  ${GREEN}║${NC}\n" "GPUs detectadas:" "$GPU_COUNT"
printf "${GREEN}║  ${NC}%-20s ${GREEN}%10s GB ${GREEN}║${NC}\n" "VRAM total (est.):" "$TOTAL_VRAM"
printf "${GREEN}║  ${NC}%-20s ${GREEN}%10s  ${GREEN}║${NC}\n" "ctx-size:" "$CTX_SIZE"
printf "${GREEN}║  ${NC}%-20s ${GREEN}%10s  ${GREEN}║${NC}\n" "split-mode:" "$SPLIT_MODE"
printf "${GREEN}║  ${NC}%-20s ${GREEN}%10s  ${GREEN}║${NC}\n" "Puerto:" "$PORT"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""

# Start service?
echo "Iniciar servicio ahora? [y/N]"
read -r START_NOW
if [ "$START_NOW" = "y" ] || [ "$START_NOW" = "Y" ]; then
    systemctl enable llama-server
    systemctl start llama-server
    echo -e "${GREEN}[✓] Service started.${NC}"
    echo "  Status: systemctl status llama-server"
    echo "  Logs:   journalctl -u llama-server -f"
else
    echo "  To start later:"
    echo "    sudo systemctl enable llama-server"
    echo "    sudo systemctl start llama-server"
fi

echo ""
echo -e "${BLUE}Para probar:${NC}"
echo "  curl -s http://localhost:$PORT/v1/chat/completions \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"model\":\"model\",\"messages\":[{\"role\":\"user\",\"content\":\"Hola\"}],\"max_tokens\":50}'"
echo ""
echo -e "${BLUE}Documentacion:${NC}"
echo "  less $SCRIPT_DIR/GUIA_RAPIDA.md"
