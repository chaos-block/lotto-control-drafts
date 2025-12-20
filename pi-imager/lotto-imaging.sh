#!/bin/bash
set -euo pipefail

# === Lotto Fleet Full Imaging Script – Pulled from GitHub ===
# Executed by bootstrap launcher with TAILSCALE_AUTHKEY exported

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # pi-imager/ dir
CUSTOM_SRC="$REPO_DIR/custom"
TEMP_CUSTOM="lotto-custom-os"
OS_IMAGE="raspios-lite-arm64.img.xz"
MINER_REPO_URL="$(cat "$REPO_DIR/miner-repo.txt" 2>/dev/null || echo "https://github.com/chaos-block/lotto-miner-scripts.git")"

if [ -z "${TAILSCALE_AUTHKEY:-}" ]; then
    echo "Error: TAILSCALE_AUTHKEY not provided!"
    exit 1
fi

echo "=== Running Lotto Imaging – GitHub Pulled Edition – 19 Dec 2025 ==="

# Auto-install rpi-imager
if ! command -v rpi-imager &> /dev/null; then
    echo "Installing rpi-imager..."
    sudo apt update && sudo apt install -y rpi-imager
fi

# Download OS
if [ ! -f "$OS_IMAGE" ]; then
    echo "Downloading latest Raspberry Pi OS Lite 64-bit..."
    OS_URL=$(wget -qO- https://downloads.raspberrypi.com/os_images.json | grep -A5 '"name":"Raspberry Pi OS Lite (64-bit)"' | grep '"url"' | cut -d'"' -f4)
    wget "https://downloads.raspberrypi.com/$OS_URL" -O "$OS_IMAGE"
fi

# Validate custom src
if [ ! -d "$CUSTOM_SRC" ]; then
    echo "Error: custom/ subdir not found in repo!"
    exit 1
fi

# Build custom zip from repo files
rm -rf "$TEMP_CUSTOM"
cp -r "$CUSTOM_SRC" "$TEMP_CUSTOM/"

# Embed secure vars via sed (placeholders in repo files)
find "$TEMP_CUSTOM" -type f -exec sed -i "s|__TAILSCALE_KEY__|$TAILSCALE_AUTHKEY|g" {} +
find "$TEMP_CUSTOM" -type f -exec sed -i "s|__MINER_REPO_URL__|$MINER_REPO_URL|g" {} +

# Make scripts executable
find "$TEMP_CUSTOM/root/usr/local/bin" -type f -exec chmod +x {} \;

# Zip custom
zip -r lotto-custom-os.zip "$TEMP_CUSTOM/"

# Drive selection & flash
echo "Available drives:"
lsblk -d -o NAME,SIZE,MODEL

read -p "Target device (e.g., sdb): " TARGET_DEV
TARGET="/dev/$TARGET_DEV"

read -p "Flash to $TARGET with SSH enabled? Type YES: " CONFIRM
[ "$CONFIRM" != "YES" ] && echo "Aborted." && exit 1

rpi-imager --cli \
    --custom lotto-custom-os.zip \
    --ssh-enable \
    --ssh-key ~/.ssh/id_rsa.pub \
    "$OS_IMAGE" "$TARGET"

echo "=== Imaging complete – Miner ready for deployment! ==="
