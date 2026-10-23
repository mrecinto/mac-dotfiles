
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
        2>/dev/null | head -n 1
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
# WORKSPACE SWITCHING
#
# Summon the target workspace onto the focused monitor.
# Applies to numbered, special, and history navigation.
# ============================================================

switch_workspace() {
    local destination="$1"

    [ -n "$destination" ] || return 1

    if [ "$(get_current_workspace)" = "$destination" ]; then
        return 0
    fi

    aerospace summon-workspace "$destination"
}

# ============================================================
# PER-MONITOR STATE
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

[ -n "$current_monitor" ] || exit 1

load_monitor_state "$current_monitor"

# ============================================================
# SELF-HEAL NUMBERED STATE
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

        is_numbered "$target" || exit 1

        if [ "$target" = "$current_workspace" ]; then
            exit 0
        fi

        if [ "$current_numbered" != "$target" ]; then

            if [ -n "$current_numbered" ]; then
                previous_numbered="$current_numbered"
            fi

            current_numbered="$target"
        fi

        switch_workspace "$target" || exit 1

        save_monitor_state "$current_monitor"
        ;;

    # ========================================================
    # SPECIAL WORKSPACE
    # ========================================================

    special)

        is_special "$target" || exit 1

        # Same special again -> return
        if [ "$current_workspace" = "$target" ]; then

            if [ -z "$special_return" ]; then
                exit 0
            fi

            switch_workspace "$special_return"
            exit $?
        fi

        # Numbered -> special
        if ! is_special "$current_workspace"; then

            special_return="$current_workspace"
            last_special="$target"

            if is_numbered "$current_workspace"; then
                current_numbered="$current_workspace"
            fi

            switch_workspace "$target" || exit 1

            save_monitor_state "$current_monitor"
            exit 0
        fi

        # Special -> different special
        # Preserve original return workspace
        last_special="$target"

        switch_workspace "$target" || exit 1

        save_monitor_state "$current_monitor"
        ;;

    # ========================================================
    # OPTION + TAB
    # ========================================================

    toggle-special)

        # Special -> return workspace
        if is_special "$current_workspace"; then

            if [ -z "$special_return" ]; then
                exit 0
            fi

            switch_workspace "$special_return"
            exit $?
        fi

        # Numbered -> last special
        if [ -z "$last_special" ]; then
            exit 0
        fi

        special_return="$current_workspace"

        if is_numbered "$current_workspace"; then
            current_numbered="$current_workspace"
        fi

        switch_workspace "$last_special" || exit 1

        save_monitor_state "$current_monitor"
        ;;

    # ========================================================
    # OPTION + BACKTICK
    # ========================================================

    previous-numbered)

        if [ -z "$previous_numbered" ]; then
            exit 0
        fi

        destination="$previous_numbered"

        temp="$current_numbered"

        switch_workspace "$destination" || exit 1

        current_numbered="$destination"
        previous_numbered="$temp"

        save_monitor_state "$current_monitor"
        ;;

    *)
        echo "Unknown action: $action" >&2
        exit 1
        ;;

esac
