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

is_numbered() {
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


# ============================================================
# STATE
#
# current_numbered
#     Most recently used numbered workspace.
#
# previous_numbered
#     Numbered workspace before current_numbered.
#
# last_special
#     Most recently used lettered workspace.
#
# special_return
#     Workspace underneath the current special overlay.
#
# Example:
#
#     2 -> 7 -> S -> D
#
# current_numbered  = 7
# previous_numbered = 2
# last_special      = D
# special_return    = 7
#
# Option+Tab:
#     D <-> 7
#
# Option+`:
#     7 <-> 2
# ============================================================

save_state() {
    {
        echo "current_numbered=${current_numbered:-}"
        echo "previous_numbered=${previous_numbered:-}"
        echo "last_special=${last_special:-}"
        echo "special_return=${special_return:-}"
    } > "$STATE"
}


# ============================================================
# LOAD STATE
# ============================================================

current_workspace="$(get_current_workspace)"

current_numbered=""
previous_numbered=""
last_special=""
special_return=""

if [ -f "$STATE" ]; then
    source "$STATE"
fi


# ============================================================
# INITIALIZE
# ============================================================

if [ -z "$current_numbered" ] && is_numbered "$current_workspace"; then
    current_numbered="$current_workspace"
    save_state
fi


# ============================================================
# ACTIONS
# ============================================================

case "$action" in


    # ========================================================
    # NUMBERED WORKSPACE
    #
    # Option + 1-0
    #
    # Updates numbered history.
    # Special workspaces do not count.
    # ========================================================

    numbered)

        if [ "$target" = "$current_workspace" ]; then
            exit 0
        fi


        # ----------------------------------------------------
        # Coming from another numbered workspace
        # ----------------------------------------------------

        if is_numbered "$current_workspace"; then

            if [ "$current_workspace" != "$target" ]; then
                previous_numbered="$current_workspace"
            fi


        # ----------------------------------------------------
        # Coming from a special workspace
        #
        # current_numbered is still the numbered workspace
        # that was active underneath the special.
        # ----------------------------------------------------

        elif is_special "$current_workspace"; then

            if [ -n "$current_numbered" ] &&
               [ "$current_numbered" != "$target" ]; then

                previous_numbered="$current_numbered"
            fi
        fi


        current_numbered="$target"

        save_state

        aerospace workspace "$target"
        ;;


    # ========================================================
    # SPECIAL WORKSPACE
    #
    # Option + W/A/S/D/I/O
    #
    # The special workspace is SUMMONED to whichever monitor
    # is currently focused.
    # ========================================================

    special)


        # ----------------------------------------------------
        # SAME SPECIAL AGAIN
        #
        # Example:
        #
        # 7 -> S
        # S -> Option+S -> 7
        # ----------------------------------------------------

        if [ "$current_workspace" = "$target" ]; then

            if [ -z "$special_return" ]; then
                exit 0
            fi

            aerospace workspace "$special_return"

            exit 0
        fi


        # ----------------------------------------------------
        # NUMBERED -> SPECIAL
        #
        # Establish the workspace underneath the overlay.
        #
        # Example:
        #
        # 7 -> S
        #
        # special_return = 7
        # ----------------------------------------------------

        if is_numbered "$current_workspace"; then

            current_numbered="$current_workspace"
            special_return="$current_workspace"
            last_special="$target"

            save_state

            aerospace summon-workspace "$target"

            exit 0
        fi


        # ----------------------------------------------------
        # SPECIAL -> DIFFERENT SPECIAL
        #
        # Keep the SAME underlying workspace.
        #
        # Example:
        #
        # 7 -> S -> D -> W
        #
        # special_return remains 7.
        # ----------------------------------------------------

        if is_special "$current_workspace"; then

            last_special="$target"

            save_state

            aerospace summon-workspace "$target"

            exit 0
        fi


        # ----------------------------------------------------
        # FALLBACK
        # ----------------------------------------------------

        special_return="$current_workspace"
        last_special="$target"

        save_state

        aerospace summon-workspace "$target"
        ;;


    # ========================================================
    # OPTION + TAB
    #
    # Toggle:
    #
    # last normal workspace <-> last lettered workspace
    #
    # Example:
    #
    # 7 -> S
    #
    # Option+Tab -> 7
    # Option+Tab -> S
    # Option+Tab -> 7
    #
    #
    # Another example:
    #
    # 7 -> S -> D
    #
    # Option+Tab -> 7
    # Option+Tab -> D
    # ========================================================

    toggle-special)


        # ----------------------------------------------------
        # CURRENTLY ON SPECIAL
        #
        # Return to workspace underneath it.
        # ----------------------------------------------------

        if is_special "$current_workspace"; then

            if [ -z "$special_return" ]; then
                exit 0
            fi

            aerospace workspace "$special_return"

            exit 0
        fi


        # ----------------------------------------------------
        # CURRENTLY ON NORMAL WORKSPACE
        #
        # This becomes the new return point.
        #
        # Then summon the most recently used special onto
        # THIS monitor.
        # ----------------------------------------------------

        if [ -z "$last_special" ]; then
            exit 0
        fi


        special_return="$current_workspace"


        if is_numbered "$current_workspace"; then
            current_numbered="$current_workspace"
        fi


        save_state

        aerospace summon-workspace "$last_special"
        ;;


    # ========================================================
    # OPTION + `
    #
    # Toggle between the two most recently used NUMBERED
    # workspaces.
    #
    # Lettered workspaces are completely ignored.
    #
    # Example:
    #
    # 2 -> 4 -> S -> D
    #
    # Option+` -> 2
    # Option+` -> 4
    # Option+` -> 2
    # ========================================================

    previous-numbered)

        if [ -z "$previous_numbered" ]; then
            exit 0
        fi


        destination="$previous_numbered"


        # Swap numbered history
        temp="$current_numbered"

        current_numbered="$previous_numbered"
        previous_numbered="$temp"

        save_state

        aerospace workspace "$destination"
        ;;

esac
