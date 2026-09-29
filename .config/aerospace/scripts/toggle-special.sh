#!/bin/bash

SPECIAL_STATE="/tmp/aerospace-last-special-$USER"
RETURN_STATE="/tmp/aerospace-special-return-$USER"

# No special has been recorded yet
[ ! -f "$SPECIAL_STATE" ] && exit 0

last_special="$(cat "$SPECIAL_STATE")"
current="$(aerospace list-workspaces --focused | head -n 1)"


# ============================================================
# We're currently on the last special.
#
# Return to wherever we were before opening it with Option+`.
# ============================================================

if [ "$current" = "$last_special" ]; then

    if [ -f "$RETURN_STATE" ]; then
        return_workspace="$(cat "$RETURN_STATE")"

        if [ -n "$return_workspace" ]; then
            aerospace workspace "$return_workspace"
        fi
    fi

    exit 0
fi


# ============================================================
# We're somewhere else.
#
# Remember this workspace and open the last special.
# ============================================================

echo "$current" > "$RETURN_STATE"

aerospace workspace "$last_special"
