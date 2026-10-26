#!/bin/sh
set -eu

helper_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_file="$helper_dir/menu-bridge.swift"
source_version=$(cksum < "$source_file" | awk '{print $1}')
build_root="${TMPDIR:-/tmp}/sketchybar-menu-bridge-$(id -u)"
cache_dir="$build_root/$source_version"
mkdir -p "$cache_dir"
if [ ! -x "$cache_dir/sb-menu-bridge" ]; then
  # Keep the bar visible if compilation fails; reuse modules across source edits.
  sketchybar --bar hidden=off y_offset=0
  xcrun swiftc -O -module-cache-path "$build_root/modules" "$source_file" -o "$cache_dir/sb-menu-bridge"
fi
exec "$cache_dir/sb-menu-bridge" "$(command -v sketchybar)"
