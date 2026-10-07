#!/bin/bash

FILE="$1"
PORT=23635

PID_FILE="/tmp/tinymist-preview.pid"
LOG_FILE="/tmp/tinymist-preview.log"

# ============================================================
# VALIDATE
# ============================================================

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    exit 1
fi


# ============================================================
# STOP OLD PREVIEW SERVER
# ============================================================

if [ -f "$PID_FILE" ]; then
    OLD_PID="$(cat "$PID_FILE")"

    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
    fi

    rm -f "$PID_FILE"
fi


# ============================================================
# START TINYMIST PREVIEW
#
# Do NOT use --open.
# We will open the URL ourselves in a new Zen window.
# ============================================================

tinymist preview "$FILE" \
    --data-plane-host="127.0.0.1:$PORT" \
    >"$LOG_FILE" 2>&1 &

PREVIEW_PID=$!
echo "$PREVIEW_PID" > "$PID_FILE"


# ============================================================
# WAIT FOR PREVIEW SERVER
# ============================================================

sleep 1


# ============================================================
# OPEN NEW ZEN WINDOW
#
# This is the exact mechanism we just verified works:
#
# Cmd+Shift+N -> new Zen window
# Cmd+L       -> address bar
# URL         -> Tinymist preview
# ============================================================

URL="http://127.0.0.1:$PORT"

osascript \
    -e 'tell application "Zen" to activate' \
    -e 'delay 0.3' \
    -e 'tell application "System Events"' \
    -e 'tell process "Zen"' \
    -e 'keystroke "n" using {command down, shift down}' \
    -e 'delay 0.7' \
    -e 'keystroke "l" using {command down}' \
    -e "keystroke \"$URL\"" \
    -e 'key code 36' \
    -e 'end tell' \
    -e 'end tell'
