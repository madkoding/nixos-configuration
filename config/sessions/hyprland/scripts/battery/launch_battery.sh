#!/usr/bin/env bash

QML_PATH="$HOME/.config/hypr/scripts/battery/BatteryPopup.qml"

# Toggle logic: If running, kill it. If not, start it.
if pgrep -f "quickshell.*BatteryPopup.qml" > /dev/null; then
    pkill -f "quickshell.*BatteryPopup.qml"
    exit 0
fi

quickshell -p "$QML_PATH" &

# Optional: Focus the window to allow closing with the Escape key
sleep 0.1
hyprctl dispatch focuswindow "quickshell"
