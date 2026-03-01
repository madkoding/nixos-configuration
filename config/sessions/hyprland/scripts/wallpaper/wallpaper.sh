#!/usr/bin/env bash

# CONFIG
QML_PATH="$HOME/.config/hypr/scripts/wallpaper/WallpaperPicker.qml"
SRC_DIR="$HOME/Images/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper_picker/thumbs"

# 1. Kill if running
if pgrep -f "quickshell.*WallpaperPicker.qml" > /dev/null; then
    pkill -f "quickshell.*WallpaperPicker.qml"
    exit 0
fi

# 2. Cleanup and Sync Thumbs (Backgrounded)
mkdir -p "$THUMB_DIR"
(
    # --- CLEANUP: Remove thumbnails that no longer have a source wallpaper ---
    for thumb in "$THUMB_DIR"/*; do
        [ -e "$thumb" ] || continue
        filename=$(basename "$thumb")
        
        # Remove "000_" prefix to check against real source file
        clean_name="${filename#000_}"
        
        if [ ! -f "$SRC_DIR/$clean_name" ]; then
            rm "$thumb"
        fi
    done

    # --- GENERATE: Create thumbnails for new or renamed wallpapers ---
    for img in "$SRC_DIR"/*.{jpg,jpeg,png,webp,gif,mp4,mkv,mov,webm}; do
        [ -e "$img" ] || continue
        filename=$(basename "$img")
        extension="${filename##*.}"

        # Determine if video to apply sorting prefix
        if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
            # Prefix video thumbs with 000_ so they appear first in the list
            thumb="$THUMB_DIR/000_$filename"
            
            # Ensure we don't have a non-prefixed old version lying around
            [ -f "$THUMB_DIR/$filename" ] && rm "$THUMB_DIR/$filename"
            
            if [ ! -f "$thumb" ]; then
                 ffmpeg -y -ss 00:00:05 -i "$img" -vframes 1 -f image2 -q:v 2 "$thumb" > /dev/null 2>&1
            fi
        else
            # Standard images
            thumb="$THUMB_DIR/$filename"
            if [ ! -f "$thumb" ]; then
                magick "$img" -resize x420 -quality 70 "$thumb"
            fi
        fi
    done
) &

# 3. Launch Quickshell
# 3. Detect Active Wallpaper & Calculate Index
TARGET_INDEX=0
CURRENT_SRC=""

# Try to find running mpvpaper file
if pgrep -a "mpvpaper" > /dev/null; then
    # Extract filename from running mpvpaper process args
    CURRENT_SRC=$(pgrep -a mpvpaper | grep -o "$SRC_DIR/[^' ]*" | head -n1)
    CURRENT_SRC=$(basename "$CURRENT_SRC")
fi

# If no mpvpaper found, try swww
if [ -z "$CURRENT_SRC" ] && command -v swww >/dev/null; then
    # swww query output: "DP-1: /path/to/image.jpg ..."
    CURRENT_SRC=$(swww query 2>/dev/null | grep -o "$SRC_DIR/[^ ]*" | head -n1)
    CURRENT_SRC=$(basename "$CURRENT_SRC")
fi

if [ -n "$CURRENT_SRC" ]; then
    # Determine expected thumbnail name (add 000_ prefix for videos)
    EXT="${CURRENT_SRC##*.}"
    if [[ "${EXT,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
        TARGET_THUMB="000_$CURRENT_SRC"
    else
        TARGET_THUMB="$CURRENT_SRC"
    fi

    # Find index in the thumb dir (sorted alphabetically to match FolderListModel)
    MATCH_LINE=$(ls -1 "$THUMB_DIR" | grep -nF "$TARGET_THUMB" | cut -d: -f1)
    
    if [ -n "$MATCH_LINE" ]; then
        TARGET_INDEX=$((MATCH_LINE - 1))
    fi
fi

export WALLPAPER_INDEX="$TARGET_INDEX"

# 4. Launch Quickshell
quickshell -p "$QML_PATH" &

# 5. FORCE FOCUS
sleep 0.2
hyprctl dispatch focuswindow "quickshell"

