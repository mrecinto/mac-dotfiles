#!/bin/bash
set -eu
. "$CONFIG_DIR/theme/colors.sh"
. "$CONFIG_DIR/theme/popup.sh"
mkdir -p "$THEME_CACHE"
# Refresh app metadata on the fallback timer or when opening the menu.
# Workspace events reuse it so highlighting never waits for app enumeration.
cache="$THEME_CACHE/workspaces.tsv"
if [ "${SENDER:-}" != aerospace_workspace_change ] || [ ! -r "$cache" ]; then
  windows=$(aerospace list-windows --all --json --format '%{workspace}%{app-name}') || exit 0
  printf '%s' "$windows" | jq -r 'group_by(.workspace)[] | [.[0].workspace, (map(.["app-name"]) | unique | join(", "))] | @tsv' > "$cache.$$"
  mv "$cache.$$" "$cache"
fi
occupied=""
for sid in W A S D I O; do eval "apps_$sid=Empty"; done
while IFS=$'\t' read -r workspace apps; do
  occupied+="$workspace "
  case "$workspace" in W|A|S|D|I|O) printf -v "apps_$workspace" '%s' "$apps" ;; esac
done < "$cache"
# Read current focus after metadata refresh to avoid painting an old selection.
focused=$(aerospace list-workspaces --focused) || exit 0
visible=$(aerospace list-workspaces --monitor all --visible) || exit 0
visible=" ${visible//$'\n'/ } "
hover=""
[ ! -r "$THEME_CACHE/hover" ] || IFS= read -r hover < "$THEME_CACHE/hover" || :
args=()
for sid in {1..10}; do
  fill=0x00000000; border=0x00000000; text="$ON_BACKGROUND"; weight=Regular
  if [[ " $occupied" == *" $sid "* ]]; then border="$SURFACE_VARIANT"; fi
  if [[ "$visible" == *" $sid "* ]]; then
    fill="0x73${PRIMARY#0xff}"; border="$SURFACE_TINT"; text="$ON_PRIMARY"; weight=Bold
  fi
  if [ "$focused" = "$sid" ]; then
    fill="$PRIMARY"; border="$SURFACE_TINT"; text="$ON_PRIMARY"; weight=Bold
  fi
  if [ "$hover" = "space.$sid" ]; then
    border="$SURFACE_TINT"; text="$ON_PRIMARY"
    [ "$focused" = "$sid" ] || fill=0x00000000
  fi
  args+=(--set "space.$sid" background.color="$fill" background.border_color="$border"
    icon.color="$text" icon.font="JetBrainsMono Nerd Font:$weight:16.0")
done
special_icon="✦"; special_fill=0x00000000; special_text="$ON_BACKGROUND"
case "$focused" in
  W|A|S|D|I|O) special_icon="$focused"; special_fill="$PRIMARY"; special_text="$ON_PRIMARY" ;;
esac
args+=(--set special icon="$special_icon" icon.color="$special_text" background.color="$special_fill")
for sid in W A S D I O; do
  key="apps_$sid"
  apps="${!key}"
  [ -n "$apps" ] || apps="Empty"
  marker="$sid"; color="$POPUP_FOREGROUND"
  if [ "$focused" = "$sid" ]; then marker="✓ $sid"; color="$POPUP_ACCENT"; fi
  args+=(--set "special.$sid" icon="$marker" label="$apps" icon.color="$color" label.color="$color")
done
sketchybar "${args[@]}"
