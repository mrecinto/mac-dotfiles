#!/bin/sh
set -eu

helper_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_file="$helper_dir/menu-bridge.swift"
source_version=$(cksum < "$source_file" | awk '{print $1}')
cache_dir="${TMPDIR:-/tmp}/sketchybar-menu-bridge-$(id -u)-$source_version"
mkdir -p "$cache_dir"
if [ ! -x "$cache_dir/sb-menu-bridge" ]; then
  xcrun swiftc -O -module-cache-path "$cache_dir/modules" "$source_file" -o "$cache_dir/sb-menu-bridge"
fi
exec "$cache_dir/sb-menu-bridge" "$(command -v sketchybar)"
