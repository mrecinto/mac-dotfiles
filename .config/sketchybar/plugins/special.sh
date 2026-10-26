#!/bin/sh
set -eu
. "$CONFIG_DIR/theme/colors.sh"
. "$CONFIG_DIR/theme/popup.sh"
case "${1:-}" in
  theme)
    mkdir -p "$THEME_CACHE"
    previous=$(cat "$THEME_CACHE/popup-mode" 2>/dev/null || true)
    [ "$previous" != "$POPUP_MODE" ] || exit 0
    sketchybar --set special popup.background.color="$POPUP_BACKGROUND" \
      popup.background.border_color="$POPUP_BORDER"
    /bin/bash "$CONFIG_DIR/plugins/workspaces.sh"
    printf '%s\n' "$POPUP_MODE" > "$THEME_CACHE/popup-mode"
    ;;
  toggle)
    /bin/bash "$CONFIG_DIR/plugins/workspaces.sh"
    sketchybar --set special popup.drawing=toggle
    ;;
  W|A|S|D|I|O)
    # Reuse keyboard navigation's summon and return-to-origin behavior.
    /bin/bash "$HOME/.config/aerospace/scripts/workspace.sh" special "$1"
    sketchybar --set special popup.drawing=off
    /bin/bash "$CONFIG_DIR/plugins/workspaces.sh"
    ;;
  hover)
    case "$SENDER" in
      mouse.entered) sketchybar --set "$NAME" background.drawing=on background.color="0x33${POPUP_ACCENT#0xff}" ;;
      mouse.exited) sketchybar --set "$NAME" background.drawing=off ;;
    esac
    ;;
esac
