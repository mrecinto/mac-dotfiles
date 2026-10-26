#!/bin/bash
# Move a snapshot of the current workspace, then follow the group.
set -euo pipefail

target=${1:-}
case "$target" in
  1|2|3|4|5|6|7|8|9|10) ;;
  *) echo 'Expected a destination workspace from 1 to 10' >&2; exit 1 ;;
esac

lock="${TMPDIR:-/tmp}/aerospace-move-group-$(id -u).lock"
mkdir "$lock" 2>/dev/null || exit 1
trap 'rmdir "$lock"' EXIT

source_workspace=$(aerospace list-workspaces --focused)
[ -n "$source_workspace" ] || exit 1
[ "$source_workspace" != "$target" ] || exit 0

# Snapshot IDs before moving anything; never enumerate other workspaces.
windows=$(aerospace list-windows --workspace "$source_workspace" --format '%{window-id}')
[ -n "$windows" ] || exit 0
focused=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)
failed=0
while IFS= read -r window; do
  if ! aerospace move-node-to-workspace --window-id "$window" "$target"; then
    echo "Could not move window $window to workspace $target" >&2
    failed=1
  fi
done <<< "$windows"
[ "$failed" = 0 ] || exit 1

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
/bin/bash "$script_dir/workspace.sh" numbered "$target"
if [ -n "$focused" ]; then
  aerospace focus --window-id "$focused"
fi
