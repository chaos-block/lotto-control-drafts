#!/bin/bash
set -euo pipefail

# === Lotto Fleet Mass Imaging Launch Script ===
# Run on Linux Mint/Ubuntu imaging workstation
# Requirements: sudo apt install rpi-imager unzip wget xz-utils git
# Place your reusable 90-day Tailscale key below (or one of the two backups)

TAILSCALE_AUTHKEY="tskey-authkXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX"  # ← REPLACE WITH YOUR REUSABLE KEY (reuse=500)

GITHUB_REPO="https://github.com/yourname/lotto-fleet-scripts.git"  # ← REPLACE WITH YOUR REPO
CUSTOM_ZIP="lotto-github-os.zip"
OS_IMAGE="raspios-lite-arm64.img.xz"
OS_URL=$(wget -qO- https://downloads.raspberrypi.com/os_images.json | grep -A5 '"name":"Raspberry Pi OS Lite (64-bit)"' | grep '"url"' | cut -d'"' -f4)

echo "=== Lotto Fleet Imaging Launcher – 19 Dec 2025 ==="

# Download latest Raspberry Pi OS Lite if not present
if [ ! -f "$OS_IMAGE" ]; then
    echo "Downloading latest Raspberry Pi OS Lite 64-bit..."
    wget "https://downloads.raspberrypi.com/$OS_URL" -O "$OS_IMAGE"
fi

# Create minimal custom structure
rm -rf lotto-custom && mkdir -p lotto-custom/{boot,firmware,root/usr/local/bin}

cat > lotto-custom/boot/cmdline.txt <<EOF
systemd.enable=overlay=yes quiet splash
EOF

cat > lotto-custom/boot/config.txt <<EOF
dtparam=watchdog=on
dtoverlay=gpio-fan,gpio=14,temp=60000
dtoverlay=gpio-shutdown,gpio_pin=3,active_low=1,gpio_pull=up
arm_boost=1
EOF

cp lotto-custom/boot/config.txt lotto-custom/firmware/config.txt

cat > lotto-custom/root/usr/local/bin/firstboot.sh <<'EOF'
#!/bin/bash
set -euo pipefail

SERIAL=$(awk '/Serial/ {print $3}' /proc/cpuinfo)
hostnamectl set-hostname "lotto-${SERIAL: -4}"

# Pull fleet scripts from GitHub
git clone GITHUB_REPO_REPLACE /home/miner/lotto
cd /home/miner/lotto
chmod +x install-deps.sh *.sh
./install-deps.sh

# Join Tailscale with embedded reusable key
tailscale up --authkey=TAILSCALE_KEY_REPLACE --accept-risks=all --advertise-tags=tag:lotto

# Self-delete
systemctl disable firstboot.service
rm /usr/local/bin/firstboot.sh /etc/systemd/system/firstboot.service

reboot
EOF

sed -i "s|GITHUB_REPO_REPLACE|$GITHUB_REPO|g" lotto-custom/root/usr/local/bin/firstboot.sh
sed -i "s|TAILSCALE_KEY_REPLACE|$TAILSCALE_AUTHKEY|g" lotto-custom/root/usr/local/bin/firstboot.sh

chmod +x lotto-custom/root/usr/local/bin/firstboot.sh

# Create firstboot systemd service
mkdir -p lotto-custom/root/etc/systemd/system
cat > lotto-custom/root/etc/systemd/system/firstboot.service <<EOF
[Unit]
Description=Lotto Fleet First Boot Setup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/firstboot.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Zip custom overlay
zip -r "$CUSTOM_ZIP" lotto-custom/

echo "Custom zip created: $CUSTOM_ZIP"

# List available drives
echo "Available drives:"
lsblk -d -o NAME,SIZE,MODEL

read -p "Enter target device (e.g. sdb or mmcblk0): " TARGET_DEV
TARGET="/dev/$TARGET_DEV"

read -p "Flash to $TARGET ? Type YES to confirm: " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted."
    exit 1
fi

# Flash with rpi-imager CLI + customization
rpi-imager --cli \
    --custom "$CUSTOM_ZIP" \
    --ssh-enable \
    --ssh-key ~/.ssh/id_rsa.pub \
    --hostname lotto-%SERIAL% \
    --locale en_US.UTF-8 \
    "$OS_IMAGE" "$TARGET"

echo "=== Flash complete! Eject $TARGET safely and deploy miner. ==="
echo "Miner will pull all scripts from GitHub and join Tailscale on first boot."
echo "SSH available immediately via your public key for recovery."
