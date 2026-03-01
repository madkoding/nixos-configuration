#!/usr/bin/env bash

# Paths
QML_PATH="$HOME/.config/hypr/scripts/network/NetworkPopup.qml"
BT_PID_FILE="$HOME/.cache/bt_scan_pid"
BT_SCAN_LOG="$HOME/.cache/bt_scan.log"

# 1. Toggle Logic: If it's already running, kill it and clean up.
if pgrep -f "quickshell.*NetworkPopup.qml" > /dev/null; then
    pkill -f "quickshell.*NetworkPopup.qml"
    
    # Cleanup Bluetooth scanning
    if [ -f "$BT_PID_FILE" ]; then
        kill $(cat "$BT_PID_FILE") 2>/dev/null
        rm "$BT_PID_FILE"
    fi
    bluetoothctl scan off > /dev/null 2>&1
    
    exit 0
fi

# 2. Pre-launch Actions (Only runs when opening)
# A. Start Bluetooth Scan in background
echo "" > "$BT_SCAN_LOG"
{ echo "scan on"; sleep infinity; } | stdbuf -oL bluetoothctl > "$BT_SCAN_LOG" 2>&1 &
echo $! > "$BT_PID_FILE"

# B. Trigger WiFi Rescan
(nmcli device wifi rescan) &

# 3. Launch Quickshell
quickshell -p "$QML_PATH" &

# 4. Force focus so Escape key closes it
sleep 0.1
hyprctl dispatch focuswindow "quickshell"
