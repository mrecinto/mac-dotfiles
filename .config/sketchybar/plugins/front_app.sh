#!/bin/sh
# AeroSpace already has Accessibility access, including focused window titles.
title=$(aerospace list-windows --focused --format '%{window-title} — %{app-name}' 2>/dev/null) || title=""
sketchybar --set "$NAME" label="$title"
