wifi::push_to_fleet() {
    [[ -f "$WIFI_ENCRYPTED" ]] || { echo "Missing $WIFI_ENCRYPTED"; exit 1; }
    miners::discover
    age -d -i <(echo "$WIFI_PASSPHRASE") "$WIFI_ENCRYPTED" > /tmp/known-networks.json

    jq -r '.[].hostname' "$MINERS_JSON" | while read -r host; do
        echo "Pushing Wi-Fi policy → $host"
        scp /tmp/known-networks.json "$host:/tmp/" &&
        ssh "$host" 'sudo cp /tmp/known-networks.json /etc/wifi-policy.json && sudo systemctl restart wifi-sync.service' ||
        echo "$host unreachable – will sync on next timer"
    done
    rm -f /tmp/known-networks.json
    telegram::send "Wi-Fi policy pushed to fleet"
}
