#!/bin/sh
# Invoked by SketchyBar every second; generate only when the image changes.
set -eu
export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"
. "$CONFIG_DIR/theme/colors.sh"
mkdir -p "$THEME_CACHE"
# A failed check releases the lock and is retried on the next tick.
mkdir "$THEME_CACHE/lock" 2>/dev/null || exit 0
trap 'rmdir "$THEME_CACHE/lock"' EXIT
command -v matugen >/dev/null || exit 0
source_file="$CONFIG_DIR/helpers/wallpaper.swift"
version=$(cksum < "$source_file" | awk '{print $1}')
helper="$THEME_CACHE/wallpaper-$version"
if [ ! -x "$helper" ]; then
  xcrun swiftc -O -module-cache-path "$THEME_CACHE/modules" "$source_file" -o "$helper"
fi
wallpaper=$("$helper")
[ -f "$wallpaper" ] || exit 0
signature=$( { printf '%s\n' "$wallpaper"; stat -f '%m:%z' "$wallpaper"; cksum < "$CONFIG_DIR/theme/colors.template"; cksum < "$CONFIG_DIR/plugins/wallpaper.sh"; cksum < "$CONFIG_DIR/helpers/app-colors.sh"; cksum < "$CONFIG_DIR/theme/ghostty-light.template"; cksum < "$CONFIG_DIR/theme/ghostty-light.palette"; cksum < "$CONFIG_DIR/theme/ghostty-dark.palette"; } | shasum -a 256)
[ ! -r "$THEME_CACHE/signature" ] || [ "$signature" != "$(cat "$THEME_CACHE/signature")" ] || exit 0
# Cache by image content and generation settings, independent of filename.
# Hash the image only after its path/metadata changes, not on every timer tick.
key=$( { shasum -a 256 < "$wallpaper"; cat "$CONFIG_DIR/theme/colors.template";
  matugen --version; printf '%s\n' 'normalize-512-v1 dark source-color-index=0'; } | shasum -a 256 | awk '{print $1}')
mkdir -p "$THEME_CACHE/palettes"
palette="$THEME_CACHE/palettes/$key.sh"
valid_palette() {
  [ -r "$1" ] && [ "$(wc -l < "$1" | tr -d ' ')" = 7 ] &&
    ! LC_ALL=C grep -Eqv '^[A-Z_]+=0x[0-9a-fA-F]{8}$' "$1"
}
if ! valid_palette "$palette"; then
  # Keep generated files outside the Nix-managed config and the Git checkout.
  cat > "$THEME_CACHE/config.toml" <<EOF
[config]
[config.wallpaper]
command = "true"
set = false
[templates.sketchybar]
input_path = '$CONFIG_DIR/theme/colors.template'
output_path = '$THEME_CACHE/colors.next.sh'
EOF
  # Normalize mislabeled images without changing the original.
  magick "$wallpaper" -auto-orient -thumbnail '512x512>' -strip "$THEME_CACHE/source.png"
  matugen -c "$THEME_CACHE/config.toml" image "$THEME_CACHE/source.png" --source-color-index 0
  valid_palette "$THEME_CACHE/colors.next.sh"
  mv "$THEME_CACHE/colors.next.sh" "$palette"
fi
cp "$palette" "$THEME_CACHE/colors.next.sh"
mv "$THEME_CACHE/colors.next.sh" "$THEME_CACHE/colors.sh"
sh "$CONFIG_DIR/helpers/app-colors.sh"
sketchybar --reload
# Commit the signature only after applying the palette succeeds.
printf '%s\n' "$signature" > "$THEME_CACHE/signature"
