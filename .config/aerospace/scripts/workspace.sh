#!/bin/bash

STATE="/tmp/aerospace-workspace-state-$USER"

action="$1"
target="$2"


# ============================================================
# HELPERS
# ============================================================

get_current_workspace() {
    aerospace list-workspaces --focused 2>/dev/null | head -n 1
}

is_normal() {
    case "$1" in
        1|2|3|4|5|6|7|8|9|10)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

is_special() {
    case "$1" in
        W|A|S|D|I|O)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

save_state() {
    {
        echo "current_normal=${current_normal:-}"
        echo "previous_normal=${previous_normal:-}"
        echo "last_special=${last_special:-}"
    } > "$STATE"
}


# ============================================================
# LOAD STATE
# ============================================================

current_workspace="$(get_current_workspace)"

if [ -f "$STATE" ]; then
    source "$STATE"
fi


# ============================================================
# INITIALIZE
# ============================================================

if [ -z "$current_normal" ] && is_normal "$current_workspace"; then
    current_normal="$current_workspace"
    save_state
fi


# ============================================================
# ACTIONS
# ============================================================

case "$action" in


    # ========================================================
    # NORMAL WORKSPACE
    #
    # 1 -> 2
    #
    # current_normal  = 2
    # previous_normal = 1
    # ========================================================

    normal)

        # Going to the numbered workspace we're already
        # logically on doesn't modify history.
        #
        # This also lets:
        #
        # 2 -> D -> Option+2 -> 2
        #
        # without destroying previous_normal.
        if [ "$target" = "$current_normal" ]; then
            aerospace workspace "$target"
            exit 0
        fi

        if [ -n "$current_normal" ]; then
            previous_normal="$current_normal"
        fi

        current_normal="$target"

        save_state

        aerospace workspace "$target"
        ;;


    # ========================================================
    # SPECIAL WORKSPACE
    #
    # W/A/S/D/I/O
    #
    # Specials never modify normal history.
    # ========================================================

    special)

        # Remember this as the most recently used special.
        last_special="$target"


        # If we're already on this special, pressing the same
        # key closes it and returns to current_normal.
        #
        # 2 -> D -> D -> 2
        if [ "$current_workspace" = "$target" ]; then

            save_state

            if [ -n "$current_normal" ]; then
                aerospace workspace "$current_normal"
            fi

            exit 0
        fi


        # Safety initialization
        if [ -z "$current_normal" ] && is_normal "$current_workspace"; then
            current_normal="$current_workspace"
        fi

        save_state

        aerospace workspace "$target"
        ;;


    # ========================================================
    # OPTION + TAB
    #
    # Previous NUMBERED workspace.
    #
    # Special workspace is ignored.
    #
    # Example:
    #
    # 1 -> 2 -> D
    #
    # Option+Tab -> 1
    #
    # Numbered state becomes:
    #
    # current_normal  = 1
    # previous_normal = 2
    #
    # Option+Tab again -> 2
    # ========================================================

    previous)

        if [ -z "$previous_normal" ]; then
            exit 0
        fi

        temp="$current_normal"

        current_normal="$previous_normal"
        previous_normal="$temp"

        save_state

        aerospace workspace "$current_normal"
        ;;


    # ========================================================
    # OPTION + `
    #
    # Toggle current numbered workspace <-> last special.
    #
    # Example:
    #
    # 2 -> D
    #
    # Option+` -> 2
    # Option+` -> D
    # Option+` -> 2
    #
    # Normal history is NEVER changed.
    # ========================================================

    toggle-special)

        # No special has been used yet.
        if [ -z "$last_special" ]; then
            exit 0
        fi


        # -----------------------------------------------
        # Currently on a special
        #
        # Return to the numbered workspace underneath.
        # -----------------------------------------------

        if is_special "$current_workspace"; then

            if [ -n "$current_normal" ]; then
                aerospace workspace "$current_normal"
            fi

            exit 0
        fi


        # -----------------------------------------------
        # Currently on a normal workspace.
        #
        # Make sure current_normal reflects where we
        # actually are.
        # -----------------------------------------------

        if is_normal "$current_workspace"; then
            current_normal="$current_workspace"
            save_state
        fi


        # -----------------------------------------------
        # Restore last special.
        # -----------------------------------------------

        aerospace workspace "$last_special"
        ;;

esac
