#!/bin/sh
interface=$(/sbin/route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
if [ -n "$interface" ]; then
  sketchybar --set "$NAME" icon=󰖩
else
  sketchybar --set "$NAME" icon=󰖪
fi
