
#!/bin/bash

STATE_DIR="/tmp/aerospace-workspace-state-$USER"
mkdir -p "$STATE_DIR" || exit 1

action="$1"
target="$2"

# ============================================================
# HELPERS
# ============================================================

is_numbered() {
    case "$1" in
        1|2|3|4|5|6|7|8|9|10) return 0 ;;
        *) return 1 ;;
    esac
}

is_special() {
    case "$1" in
        W|A|S|D|I|O) return 0 ;;
        *) return 1 ;;
    esac
}

# ============================================================
# INITIAL STATE
# ============================================================

current_workspace="$(
    aerospace list-workspaces --focused 2>/dev/null
)"

monitor="$(
    aerospace list-monitors --focused \
        --format '%{monitor-id}' 2>/dev/null
)"

[ -n "$current_workspace" ] || exit 1
[ -n "$monitor" ] || exit 1

# ============================================================
# PER-MONITOR STATE
# ============================================================

state_file="$STATE_DIR/monitor-$monitor"
lock_dir="$STATE_DIR/monitor-$monitor.lock"

# Prevent concurrent updates to this monitor's history.
# Lock acquisition is bounded to avoid hanging indefinitely.
attempt=0
until mkdir "$lock_dir" 2>/dev/null; do
    attempt=$((attempt + 1))
    [ "$attempt" -lt 20 ] || exit 1
    sleep 0.01
done

trap 'rmdir "$lock_dir" 2>/dev/null' EXIT

current_numbered=""
previous_numbered=""
last_special=""
special_return=""

if [ -f "$state_file" ]; then
    {
        IFS= read -r current_numbered || :
        IFS= read -r previous_numbered || :
        IFS= read -r last_special || :
        IFS= read -r special_return || :
    } < "$state_file"
fi

# Reject invalid saved values.
is_numbered "$current_numbered" || current_numbered=""
is_numbered "$previous_numbered" || previous_numbered=""
is_special "$last_special" || last_special=""

if ! is_numbered "$special_return"; then
    special_return=""
fi

save_state() {
    local tmp="$state_file.$$"

    printf '%s\n' \
        "$current_numbered" \
        "$previous_numbered" \
        "$last_special" \
        "$special_return" > "$tmp" || return 1

    mv -f "$tmp" "$state_file"
}

# ============================================================
# WORKSPACE SWITCHING
# ============================================================

switch_workspace() {
    local destination="$1"

    [ -n "$destination" ] || return 1

    if [ "$current_workspace" = "$destination" ]; then
        return 0
    fi

    aerospace summon-workspace "$destination" || return 1

    current_workspace="$destination"
}

# ============================================================
# SYNC NUMBERED HISTORY
# ============================================================

if is_numbered "$current_workspace" &&
   [ "$current_numbered" != "$current_workspace" ]; then

    if is_numbered "$current_numbered"; then
        previous_numbered="$current_numbered"
    fi

    current_numbered="$current_workspace"
    save_state || exit 1
fi

# ============================================================
# ACTIONS
# ============================================================

case "$action" in

    # --------------------------------------------------------
    # NUMBERED WORKSPACE
    # --------------------------------------------------------

    numbered)
        is_numbered "$target" || exit 1

        [ "$target" = "$current_workspace" ] && exit 0

        old_numbered="$current_numbered"

        switch_workspace "$target" || exit 1

        if [ "$old_numbered" != "$target" ]; then
            if is_numbered "$old_numbered"; then
                previous_numbered="$old_numbered"
            fi
            current_numbered="$target"
        fi

        save_state
        ;;

    # --------------------------------------------------------
    # SPECIAL WORKSPACE
    # --------------------------------------------------------

    special)
        is_special "$target" || exit 1

        # Pressing the same special key returns to its origin.
        if [ "$current_workspace" = "$target" ]; then
            [ -n "$special_return" ] || exit 0
            switch_workspace "$special_return"
            exit $?
        fi

        # Entering from a numbered workspace.
        if is_numbered "$current_workspace"; then
            origin="$current_workspace"

            switch_workspace "$target" || exit 1

            special_return="$origin"
            last_special="$target"
            current_numbered="$origin"

            save_state
            exit $?
        fi

        # Switching between special workspaces.
        # Preserve the original numbered return destination.
        switch_workspace "$target" || exit 1

        last_special="$target"
        save_state
        ;;

    # --------------------------------------------------------
    # OPTION + TAB
    # --------------------------------------------------------

    toggle-special)

        # Special -> original numbered workspace.
        if is_special "$current_workspace"; then
            [ -n "$special_return" ] || exit 0
            switch_workspace "$special_return"
            exit $?
        fi

        # Numbered -> this monitor's last special workspace.
        is_special "$last_special" || exit 0
        is_numbered "$current_workspace" || exit 0

        origin="$current_workspace"
        destination="$last_special"

        switch_workspace "$destination" || exit 1

        special_return="$origin"
        current_numbered="$origin"

        save_state
        ;;

    # --------------------------------------------------------
    # OPTION + BACKTICK
    # --------------------------------------------------------

    previous-numbered)
        is_numbered "$previous_numbered" || exit 0

        destination="$previous_numbered"
        old_numbered="$current_numbered"

        switch_workspace "$destination" || exit 1

        current_numbered="$destination"
        previous_numbered="$old_numbered"

        save_state
        ;;

    *)
        echo "Unknown action: $action" >&2
        exit 1
        ;;
esac
