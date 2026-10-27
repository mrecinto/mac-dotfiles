#!/bin/sh
set -eu
. "$CONFIG_DIR/theme/colors.sh"
mkdir -p "$THEME_CACHE"
# Match CSS stops: .85 at 0%, .35 at 78%, transparent at 100%.
# The bar window clips this wide image to each display’s own bounds.
rgb=$(printf '%s' "$BACKGROUND" | cut -c5-10)
key=$( { printf '%s\n' "$rgb"; cksum < "$CONFIG_DIR/helpers/gradient.sh"; } | shasum -a 256 | awk '{print $1}')
mkdir -p "$THEME_CACHE/gradients"
image="$THEME_CACHE/gradients/$key.png"
if [ ! -r "$image" ]; then
magick -size 16384x72 "xc:#$rgb" -alpha set -channel A \
  -fx 'j/(h-1)<=0.78 ? 0.85-0.5*(j/(h-1))/0.78 : 0.35*(1-j/(h-1))/0.22' \
  -channel RGBA "$image"
fi
cp "$image" "$THEME_CACHE/gradient.png"
