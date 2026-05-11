#!/bin/bash
# llama-vulkan-rx580 :: package.sh :: v2.0.0
# Empaqueta un release para distribución
# Uso: ./scripts/package.sh [version]
#   Si no se especifica versión, lee de VERSION

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

VERSION="${1:-$(cat VERSION)}"
OUTPUT_DIR="$SCRIPT_DIR/../llama-vulkan-rx580-release-$VERSION"
ARCHIVE="llama-vulkan-rx580-v$VERSION.tar.gz"

echo "=== Packaging release v$VERSION ==="

# Validate required paths
for dir in "binaries-v$VERSION" deploy scripts systemd examples; do
    if [ ! -d "$dir" ] && [ ! -d "${dir%/}" ]; then
        echo "WARNING: $dir not found, skipping."
    fi
done

# Create temporary directory with full structure
TMPDIR=$(mktemp -d)
RELDIR="$TMPDIR/llama-vulkan-rx580-v$VERSION"
mkdir -p "$RELDIR"

# Copy all files
cp VERSION CHANGELOG.md README.md GUIA_RAPIDA.md "$RELDIR/" 2>/dev/null || true

if [ -d "binaries-v$VERSION" ]; then
    cp -a "binaries-v$VERSION" "$RELDIR/"
fi

for dir in deploy scripts systemd examples .github source; do
    [ -d "$dir" ] && cp -a "$dir" "$RELDIR/"
done

# Create tarball
cd "$TMPDIR"
tar czf "$ARCHIVE" "llama-vulkan-rx580-v$VERSION"
mv "$ARCHIVE" "$SCRIPT_DIR/"
cd "$SCRIPT_DIR"
rm -rf "$TMPDIR"

echo ""
echo "=== Package created ==="
echo "  $ARCHIVE"
echo "  Size: $(du -h "$ARCHIVE" | cut -f1)"
echo ""
echo "Extract with: tar -xzf $ARCHIVE"
