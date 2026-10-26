#!/bin/sh
. "$CONFIG_DIR/theme/colors.sh"
mkdir -p "$THEME_CACHE"
case "$SENDER" in
  mouse.entered) printf '%s\n' "$NAME" > "$THEME_CACHE/hover" ;;
  mouse.exited) printf '' > "$THEME_CACHE/hover" ;;
esac
/bin/bash "$CONFIG_DIR/plugins/workspaces.sh"
