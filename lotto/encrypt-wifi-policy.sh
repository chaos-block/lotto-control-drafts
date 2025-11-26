#!/bin/bash
set -euo pipefail
cd /opt/lotto-control/data

# EDIT THIS PASSPHRASE – 30+ random chars, write it on paper and lock in safe
PASSPHRASE="CorrectHorseBatteryStaple-2025-YourUniquePhraseHere!!"

echo "=== LOTTO FLEET – Wi-Fi POLICY ENCRYPTOR ==="
echo "This encrypts known-networks.json → known-networks.json.enc"
echo "Plaintext file will be SHREDDED after encryption"
echo

if [[ ! -f known-networks.json ]]; then
    echo "ERROR: known-networks.json not found in $(pwd)"
    echo "Create it first with all your SSIDs + passwords"
    exit 1
fi

echo "Encrypting with age (passphrase-protected)..."
age -p -o known-networks.json.enc known-networks.json <<< "$PASSPHRASE"

echo "Securely shredding plaintext..."
shred -u -z -n 7 known-networks.json

echo "DONE"
echo "Your master Wi-Fi policy is now safely stored in:"
echo "    /opt/lotto-control/data/known-networks.json.enc"
echo
echo "Update your config with the same passphrase:"
echo "    WIFI_PASSPHRASE=\"$PASSPHRASE\"   → in /opt/lotto-control/config/config.sh"
echo
echo "Push to entire fleet with:  fleet-manager push-wifi"
echo "You are now 100% centralized forever. Never touch miners again."

fleet-manager push-wifi || echo "Run fleet-manager push-wifi manually after this"
