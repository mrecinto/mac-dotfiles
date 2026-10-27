#!/bin/bash
# Keep existing bindings/callers; exec avoids an extra waiting shell process.
script_dir=${BASH_SOURCE[0]%/*}
exec /usr/bin/python3 "$script_dir/workspace.py" "$@"
