#!/bin/bash
# install-glslc.sh :: v2.0.0
# Builds and installs glslc from the shaderc project source.
# Requires: cmake, build-essential, git

set -euo pipefail

BUILD_DIR="/tmp/shaderc-build"
INSTALL_DIR="/tmp/shaderc-install"

echo "=== Building glslc from shaderc source ==="

# Clone shaderc
if [ -d "$BUILD_DIR" ]; then
    echo "Removing existing build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Cloning shaderc..."
git clone --depth 1 https://github.com/google/shaderc.git .
echo "shaderc commit: $(git rev-parse HEAD)"

# Sync dependencies via CMake FetchContent mechanism
echo "Configuring CMake (dependencies will be fetched automatically)..."
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DSHADERC_SKIP_TESTS=ON \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -G "Unix Makefiles"

echo "Building glslc..."
cmake --build build --target glslc -j"$(nproc)" 2>&1 | tail -10

echo "Installing glslc..."
cmake --install build --component glslc 2>/dev/null || true
# Fallback: find the binary directly
GLSLC_BIN=$(find "$BUILD_DIR/build" -name glslc -type f 2>/dev/null | head -1)
if [ -z "$GLSLC_BIN" ]; then
    echo "ERROR: glslc binary not found after build" >&2
    exit 1
fi

echo "Installing glslc to /usr/local/bin/..."
sudo cp "$GLSLC_BIN" /usr/local/bin/glslc
sudo chmod +x /usr/local/bin/glslc

# Verify
echo "Verifying glslc..."
glslc --version 2>&1 || true

echo "glslc installed successfully at $(which glslc)"
