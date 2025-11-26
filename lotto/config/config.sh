#!/bin/bash
# Central configuration – edit only this file

TAILNET="your-tailnet.ts.net"
CONTROL_FQDN="lotto-control.your-tailnet.ts.net"
TELEGRAM_BOT_TOKEN="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
TELEGRAM_CHAT_ID="-1001234567890"

# Paths
DATA_DIR="/opt/lotto-control/data"
MINERS_JSON="$DATA_DIR/miners.json"
WIFI_ENCRYPTED="$DATA_DIR/known-networks.json.enc"
WIFI_PASSPHRASE="SuperSecretWiFiPassphrase2025!"   # for age encryption

# Tailscale reusable fallback keys (90-day, reuse=500)
REUSABLE_KEY1="$(cat $DATA_DIR/reusable-keys/key1)"
REUSABLE_KEY2="$(cat $DATA_DIR/reusable-keys/key2)"

# Age encryption (Wi-Fi policy)
AGE_PUBLIC_KEY="age1yourpublickeyhere..."  # from lotto-control's age keypair
