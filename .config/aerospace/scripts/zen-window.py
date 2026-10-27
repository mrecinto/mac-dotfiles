#!/usr/bin/env python3
"""Open a Zen window on the workspace where the shortcut was pressed."""

import json
import subprocess
import time


def aerospace(*args):
    return subprocess.check_output(
        ["/opt/homebrew/bin/aerospace", *args], text=True
    ).strip()


def zen_windows():
    return {
        window["window-id"]
        for window in json.loads(
            aerospace("list-windows", "--all", "--json")
        )
        if window["app-name"] == "Zen"
    }


def main():
    workspace = aerospace("list-workspaces", "--focused")
    existing = zen_windows()
    # Avoid activating an existing window before requesting the new one.
    subprocess.run(
        ["/usr/bin/open", "-gna", "Zen", "--args", "--new-window", "about:blank"],
        check=True,
    )
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        new_windows = zen_windows() - existing
        if new_windows:
            window_id = str(max(new_windows))
            aerospace("move-node-to-workspace", "--window-id", window_id, workspace)
            aerospace("focus", "--window-id", window_id)
            return
        time.sleep(0.1)
    raise SystemExit("Zen did not create a new window within 15 seconds")


if __name__ == "__main__":
    main()
