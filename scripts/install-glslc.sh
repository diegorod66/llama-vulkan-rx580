#!/bin/bash
# install-glslc.sh :: v2.0.0
# Installs a glslc wrapper script that delegates to glslangValidator.
# The cmake FindVulkan module (3.28+) requires glslc to be in PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure glslangValidator is installed
if ! command -v glslangValidator &>/dev/null; then
    echo "ERROR: glslangValidator not found. Install glslang-tools package first." >&2
    exit 1
fi

# Install the wrapper as glslc
sudo cp "$SCRIPT_DIR/glslc-wrapper.sh" /usr/local/bin/glslc
sudo chmod +x /usr/local/bin/glslc

echo "glslc wrapper installed at $(which glslc)"
echo "  delegates to: $(which glslangValidator)"
