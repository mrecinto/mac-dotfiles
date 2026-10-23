#!/bin/bash

STATE_DIR="/tmp/aerospace-workspace-state-$USER"

mkdir -p "$STATE_DIR"

action="$1"
target="$2"


# ============================================================
# HELPERS
# ============================================================

get_current_workspace() {
    aerospace list-workspaces --focused 2>/dev/null | head -n 1
}

get_current_monitor() {
    aerospace list-monitors \
        --focused \
        --format '%{monitor-id}' \
        2>/dev/null |
        head -n 1
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
# PER-MONITOR STATE
#
# Every monitor remembers independently:
#
# current_numbered
# previous_numbered
# last_special
# special_return
# ============================================================

monitor_state_file() {
    echo "$STATE_DIR/monitor-$1"
}

load_monitor_state() {
    monitor="$1"

    current_numbered=""
    previous_numbered=""
    last_special=""
    special_return=""

    file="$(monitor_state_file "$monitor")"

    if [ -f "$file" ]; then
        source "$file"
    fi
}

save_monitor_state() {
    monitor="$1"

    file="$(monitor_state_file "$monitor")"

    {
        echo "current_numbered=${current_numbered:-}"
        echo "previous_numbered=${previous_numbered:-}"
        echo "last_special=${last_special:-}"
        echo "special_return=${special_return:-}"
    } > "$file"
}


# ============================================================
# INITIAL STATE
# ============================================================

current_workspace="$(get_current_workspace)"
current_monitor="$(get_current_monitor)"

load_monitor_state "$current_monitor"


# ============================================================
# SELF-HEAL NUMBERED STATE
#
# If AeroSpace navigation landed us on a numbered workspace
# without going through this script, sync this monitor's
# numbered history.
# ============================================================

if is_numbered "$current_workspace" &&
   [ "$current_numbered" != "$current_workspace" ]; then

    if [ -n "$current_numbered" ]; then
        previous_numbered="$current_numbered"
    fi

    current_numbered="$current_workspace"

    save_monitor_state "$current_monitor"
fi


# ============================================================
# ACTIONS
# ============================================================

case "$action" in


    # ========================================================
    # NUMBERED WORKSPACE
    # ========================================================

    numbered)

        if [ "$target" = "$current_workspace" ]; then
            exit 0
        fi

        if [ "$current_numbered" != "$target" ]; then

            if [ -n "$current_numbered" ]; then
                previous_numbered="$current_numbered"
            fi

            current_numbered="$target"
        fi

        save_monitor_state "$current_monitor"

        aerospace workspace "$target"
        ;;


    # ========================================================
    # SPECIAL WORKSPACE
    #
    # Always summon the special onto the CURRENT monitor.
    # ========================================================

    special)


        # ----------------------------------------------------
        # SAME SPECIAL AGAIN
        #
        # 2 -> A
        # Option+A -> 2
        # ----------------------------------------------------

        if [ "$current_workspace" = "$target" ]; then

            if [ -z "$special_return" ]; then
                exit 0
            fi

            aerospace workspace "$special_return"

            exit 0
        fi


        # ----------------------------------------------------
        # NORMAL/NUMBERED -> SPECIAL
        #
        # Establish this monitor's new return point.
        # ----------------------------------------------------

        if ! is_special "$current_workspace"; then

            special_return="$current_workspace"
            last_special="$target"

            if is_numbered "$current_workspace"; then
                current_numbered="$current_workspace"
            fi

            save_monitor_state "$current_monitor"

            aerospace summon-workspace "$target"

            exit 0
        fi


        # ----------------------------------------------------
        # SPECIAL -> DIFFERENT SPECIAL
        #
        # Keep the SAME return point.
        #
        # 2 -> A -> S -> D
        #
        # return remains 2.
        # ----------------------------------------------------

        last_special="$target"

        save_monitor_state "$current_monitor"

        aerospace summon-workspace "$target"
        ;;


    # ========================================================
    # OPTION + TAB
    #
    # Toggle this monitor's:
    #
    # return workspace <-> last special
    # ========================================================

    toggle-special)


        # ----------------------------------------------------
        # SPECIAL -> RETURN
        # ----------------------------------------------------

        if is_special "$current_workspace"; then

            if [ -z "$special_return" ]; then
                exit 0
            fi

            aerospace workspace "$special_return"

            exit 0
        fi


        # ----------------------------------------------------
        # NORMAL -> LAST SPECIAL
        # ----------------------------------------------------

        if [ -z "$last_special" ]; then
            exit 0
        fi

        special_return="$current_workspace"

        if is_numbered "$current_workspace"; then
            current_numbered="$current_workspace"
        fi

        save_monitor_state "$current_monitor"

        aerospace summon-workspace "$last_special"
        ;;


    # ========================================================
    # OPTION + `
    #
    # Per-monitor numbered history.
    # ========================================================

    previous-numbered)

        if [ -z "$previous_numbered" ]; then
            exit 0
        fi

        destination="$previous_numbered"

        temp="$current_numbered"

        current_numbered="$previous_numbered"
        previous_numbered="$temp"

        save_monitor_state "$current_monitor"

        aerospace workspace "$destination"
        ;;

esac
