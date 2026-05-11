#!/bin/bash
# llama-vulkan-rx580 :: build.sh :: v2.0.0
# Compila llama.cpp con backend Vulkan y parche para AMD Polaris (RX 580)
# Uso: ./scripts/build.sh
#
# Requisitos: Debian 12+/Ubuntu 24+, build-essential, cmake, git,
#             libvulkan-dev, vulkan-tools, lld

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
INSTALL_DIR="$SCRIPT_DIR/binaries-v2.0.0"

echo -e "${GREEN}=== llama-vulkan-rx580 :: Build v2.0.0 ===${NC}"
echo ""

# --- 1. Check prerequisites ---
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"
for cmd in cmake make git glslc vulkaninfo; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}ERROR: $cmd not found. Install build-essential cmake git libvulkan-dev vulkan-tools glslang-tools lld${NC}"
        exit 1
    fi
done
echo "  All prerequisites found."

# --- 2. Clone llama.cpp ---
echo -e "${YELLOW}[2/6] Cloning llama.cpp...${NC}"
LLAMA_DIR="$BUILD_DIR/llama.cpp"
if [ -d "$LLAMA_DIR" ]; then
    echo "  Updating existing clone..."
    cd "$LLAMA_DIR"
    git pull --ff-only
else
    mkdir -p "$BUILD_DIR"
    git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA_DIR"
    cd "$LLAMA_DIR"
fi

LLAMA_COMMIT=$(git rev-parse HEAD)
LLAMA_DATE=$(git log -1 --format=%cd)
echo "  Commit: $LLAMA_COMMIT"
echo "  Date:   $LLAMA_DATE"

# --- 3. Apply cooperative matrix patch ---
echo -e "${YELLOW}[3/6] Applying cooperative_matrix=OFF patch for Polaris...${NC}"
python3 "$SCRIPT_DIR/scripts/patch-cooperative-matrix.py" "$LLAMA_DIR"

# --- 4. Configure CMake ---
echo -e "${YELLOW}[4/6] Configuring CMake...${NC}"
mkdir -p "$LLAMA_DIR/build"
cd "$LLAMA_DIR/build"

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_VULKAN=ON \
    -DGGML_CUDA=OFF \
    -DGGML_METAL=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_LINKER_TYPE=LLD \
    -G "Unix Makefiles"

echo "  CMake configured."

# --- 5. Compile ---
echo -e "${YELLOW}[5/6] Compiling (this may take 10-20 minutes)...${NC}"
make -j"$(nproc)" 2>&1 | tail -5
echo "  Compilation finished."

# --- 6. Package ---
echo -e "${YELLOW}[6/6] Packaging to binaries-v2.0.0/...${NC}"
mkdir -p "$INSTALL_DIR"
cp "$LLAMA_DIR/build/bin/llama-server" "$INSTALL_DIR/"
# Copy all .so files (both symlinks and real files)
cp -a "$LLAMA_DIR/build/bin/"*.so* "$INSTALL_DIR/" 2>/dev/null || true

# Generate build info
cat > "$INSTALL_DIR/BUILD_INFO.txt" << EOF
llama-vulkan-rx580 v2.0.0
Built: $(date -u '+%Y-%m-%d %H:%M UTC')
llama.cpp commit: $LLAMA_COMMIT
llama.cpp date: $LLAMA_DATE
ggml: bundled with llama.cpp
Backend: Vulkan (cooperative_matrix=OFF patched)
EOF

echo ""
echo -e "${GREEN}=== Build complete! ===${NC}"
echo "  Binaries: $INSTALL_DIR/"
ls -lh "$INSTALL_DIR/"
echo ""
echo "Next step: sudo ./deploy/install.sh"
