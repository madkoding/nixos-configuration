#!/usr/bin/env bash

# CONFIG
# Change this path to wherever you saved the MusicPopup.qml file
QML_PATH="$HOME/.config/hypr/scripts/music/MusicPopup.qml"

# 1. Check if the music popup is already running
if pgrep -f "quickshell.*MusicPopup.qml" > /dev/null; then
    # If it is running, kill it (Toggle OFF)
    pkill -f "quickshell.*MusicPopup.qml"
    exit 0
fi

# 2. If it's not running, launch it (Toggle ON)
quickshell -p "$QML_PATH" &

# 3. Force focus so it appears above other things and can be interacted with
sleep 0.2
hyprctl dispatch focuswindow "title:^(music_win)$"
