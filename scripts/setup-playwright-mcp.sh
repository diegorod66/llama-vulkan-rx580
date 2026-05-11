#!/bin/bash
# setup-playwright-mcp.sh :: v2.0.0
# Installs and configures @playwright/mcp for Chrome DevTools integration.
# This enables AI agents to interact with the llama-server web UI via browser automation.
#
# Usage: bash scripts/setup-playwright-mcp.sh
#
# Prerequisites: Node.js 18+, npm

set -euo pipefail

echo "=== llama-vulkan-rx580 :: Playwright MCP Setup ==="
echo ""

# Check prerequisites
for cmd in node npm npx; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd not found. Install Node.js 18+ first." >&2
        exit 1
    fi
done

echo "Node.js: $(node --version)"
echo "npm:    $(npm --version)"
echo ""

# Install @playwright/mcp globally (or use npx for on-demand)
echo "Installing @playwright/mcp..."
npx @playwright/mcp@latest --version 2>/dev/null || true

echo ""
echo "=== Playwright MCP Ready ==="
echo ""
echo "To start the MCP server:"
echo "  npx @playwright/mcp@latest"
echo ""
echo "This exposes browser automation tools to any MCP client."
echo "Use it to debug the llama-server web UI at http://localhost:8080"
echo ""
echo "Example MCP client configuration:"
echo '  "playwright": {'
echo '    "command": "npx",'
echo '    "args": ["@playwright/mcp@latest"]'
echo '  }'
