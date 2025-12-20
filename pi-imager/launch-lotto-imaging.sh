#!/bin/bash
set -euo pipefail

# === Lotto Fleet Dynamic Imaging Launcher Bootstrap ===

REPO="https://github.com/chaos-block/lotto-control-drafts.git"
BRANCH="main"
TEMP_DIR="$(mktemp -d)"
LAUNCH_SCRIPT="pi-imager/launch-lotto-imaging.sh"

echo "=== Pulling latest launcher from GitHub – 19 Dec 2025 ==="
git clone --depth 1 --branch "$BRANCH" "$REPO" "$TEMP_DIR"

if [ ! -f "$TEMP_DIR/$LAUNCH_SCRIPT" ]; then
    echo "Error: Launch script not found in repo!"
    exit 1
fi

chmod +x "$TEMP_DIR/$LAUNCH_SCRIPT"

echo "Executing latest launch-lotto-imaging.sh from GitHub..."
exec "$TEMP_DIR/$LAUNCH_SCRIPT"

if [ -z "${TAILSCALE_AUTHKEY:-}" ]; then
    read -p "Enter your reusable Tailscale auth key (90-day, reuse=500): " TAILSCALE_AUTHKEY
fi
