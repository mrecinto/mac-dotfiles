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

    # --------------------------------------------------------
    # NUMBERED WORKSPACE
    # --------------------------------------------------------

    numbered)

        if [ "$target" = "$current_numbered" ]; then
            aerospace workspace "$target"
            exit 0
        fi

        if [ -n "$current_numbered" ]; then
            previous_numbered="$current_numbered"
        fi

        current_numbered="$target"

        save_state
        aerospace workspace "$target"
        ;;


    # --------------------------------------------------------
    # SPECIAL WORKSPACE
    # --------------------------------------------------------

    special)

        last_special="$target"

        # Press same special again -> return to numbered
        if [ "$current_workspace" = "$target" ]; then

            save_state

            if [ -n "$current_numbered" ]; then
                aerospace workspace "$current_numbered"
            fi

            exit 0
        fi

        # Keep numbered state synchronized
        if is_numbered "$current_workspace"; then
            current_numbered="$current_workspace"
        fi

        save_state
        aerospace workspace "$target"
        ;;


    # --------------------------------------------------------
    # OPTION + `
    #
    # Toggle last two NUMBERED workspaces
    # --------------------------------------------------------

    previous-numbered)

        if [ -z "$previous_numbered" ]; then
            exit 0
        fi

        temp="$current_numbered"

        current_numbered="$previous_numbered"
        previous_numbered="$temp"

        save_state
        aerospace workspace "$current_numbered"
        ;;


    # --------------------------------------------------------
    # OPTION + TAB
    #
    # Toggle current workspace <-> last SPECIAL
    # --------------------------------------------------------

    toggle-special)

        if [ -z "$last_special" ]; then
            exit 0
        fi

        # Already on the special -> go back
        if [ "$current_workspace" = "$last_special" ]; then

            if [ -n "$special_return" ]; then
                aerospace workspace "$special_return"
            elif [ -n "$current_numbered" ]; then
                aerospace workspace "$current_numbered"
            fi

            exit 0
        fi

        # Remember exactly where Option+Tab came from
        special_return="$current_workspace"

        if is_numbered "$current_workspace"; then
            current_numbered="$current_workspace"
        fi

        save_state
        aerospace workspace "$last_special"
        ;;

esac
