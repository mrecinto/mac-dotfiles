#!/bin/sh
# Derive app themes from the exact cached palette used by the bar.
set -eu
. "$CONFIG_DIR/theme/colors.sh"
bg="#${BACKGROUND#0xd9}"
fg="#${ON_BACKGROUND#0xff}"
accent="#${PRIMARY#0xff}"
on_accent="#${ON_PRIMARY#0xff}"
surface="#${SURFACE_VARIANT#0xff}"
cat > "$THEME_CACHE/ghostty-dark.next.conf" <<THEME
background = $bg
foreground = $fg
cursor-color = $accent
cursor-text = $on_accent
selection-background = $accent
selection-foreground = $on_accent
THEME
cat "$CONFIG_DIR/theme/ghostty-dark.palette" >> "$THEME_CACHE/ghostty-dark.next.conf"
mv "$THEME_CACHE/ghostty-dark.next.conf" "$THEME_CACHE/ghostty-dark.conf"
# Generate a light counterpart from the wallpaper accent, caching by seed/template.
light_key=$( { printf '%s\n' "$accent"; cat "$CONFIG_DIR/theme/ghostty-light.template"; matugen --version; } | shasum -a 256 | awk '{print $1}')
mkdir -p "$THEME_CACHE/ghostty-light"
light="$THEME_CACHE/ghostty-light/$light_key.conf"
if [ ! -r "$light" ]; then
  cat > "$THEME_CACHE/ghostty-light.toml" <<CONFIG
[config]
[config.wallpaper]
command = "true"
set = false
[templates.ghostty]
input_path = '$CONFIG_DIR/theme/ghostty-light.template'
output_path = '$light.next'
CONFIG
  matugen -c "$THEME_CACHE/ghostty-light.toml" color hex "$accent" --mode light
  mv "$light.next" "$light"
fi
cp "$light" "$THEME_CACHE/ghostty-light.next.conf"
cat "$CONFIG_DIR/theme/ghostty-light.palette" >> "$THEME_CACHE/ghostty-light.next.conf"
mv "$THEME_CACHE/ghostty-light.next.conf" "$THEME_CACHE/ghostty-light.conf"
cat > "$THEME_CACHE/ghostty.next.conf" <<THEME
# Ghostty chooses the wallpaper variant using macOS appearance.
theme = light:$THEME_CACHE/ghostty-light.conf,dark:$THEME_CACHE/ghostty-dark.conf
THEME
mv "$THEME_CACHE/ghostty.next.conf" "$THEME_CACHE/ghostty.conf"
cat > "$THEME_CACHE/zen.next.css" <<THEME
/* Generated wallpaper palette. Browser UI only. */
:root {
  --zen-primary-color: $accent !important;
  --zen-main-browser-background: $bg !important;
  --zen-main-browser-background-toolbar: $bg !important;
  --toolbar-bgcolor: $bg !important;
  --toolbar-color: $fg !important;
  --lwt-text-color: $fg !important;
  --lwt-accent-color: $bg !important;
  --sidebar-background-color: $bg !important;
  --sidebar-text-color: $fg !important;
  --toolbar-field-background-color: $surface !important;
  --toolbar-field-color: $fg !important;
  --tab-selected-bgcolor: $surface !important;
  --tab-selected-textcolor: $fg !important;
  --focus-outline-color: $accent !important;
}
THEME
mv "$THEME_CACHE/zen.next.css" "$THEME_CACHE/zen.css"
# Reload through Ghostty's own scripting API without keystrokes or focus changes.
if pgrep -x ghostty >/dev/null 2>&1; then
  osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "Ghostty"
  if (count of terminals) > 0 then
    perform action "reload_config" on (first terminal)
  end if
end tell
APPLESCRIPT
fi
