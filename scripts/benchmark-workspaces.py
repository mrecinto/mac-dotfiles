#!/usr/bin/env python3
"""Compare workspace command paths on occupied workspaces of one monitor.

This switches the desktop repeatedly. Measures process completion, not display
repaint or physical keyboard/Karabiner latency. Restores focus and script state.
"""
import argparse
import json
import math
import os
from pathlib import Path
import shutil
import statistics
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--samples', type=int, default=20)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.samples < 2 or args.samples % 2:
        parser.error('--samples must be an even number >= 2')
    cli = shutil.which('aerospace')
    if not cli:
        parser.error('aerospace is not on PATH')
    script = Path(__file__).resolve().parents[1] / '.config/aerospace/scripts/workspace.sh'
    env = dict(os.environ, PATH=f'{Path(cli).parent}:' + os.environ['PATH'])

    def run(command):
        return subprocess.run(command, env=env, check=True, capture_output=True,
                              text=True, timeout=15).stdout.strip()

    def aero(*words):
        return run([cli, *words])

    start = aero('list-workspaces', '--focused')
    focus = aero('list-windows', '--focused', '--format', '%{window-id}')
    occupied = aero('list-workspaces', '--monitor', 'focused', '--empty', 'no').splitlines()
    numbers = sorted((x for x in occupied if x.isdigit() and 1 <= int(x) <= 10), key=int)
    specials = [x for x in ('W', 'A', 'S', 'D', 'I', 'O') if x in occupied]
    if len(numbers) < 2 or not specials:
        parser.error('Need two occupied numbered workspaces and one special on the focused monitor')
    base = start if start in numbers else numbers[0]
    other = next(x for x in numbers if x != base)
    special = specials[0]
    state_dir = Path('/tmp') / f'aerospace-workspace-state-{env["USER"]}'
    state_dir.mkdir(exist_ok=True)
    if list(state_dir.glob('monitor-*.lock')):
        parser.error('A workspace history operation is in progress; retry shortly')
    saved = {p.name: p.read_bytes() for p in state_dir.glob('monitor-*') if p.is_file()}
    results = []

    def shell(action, target=None):
        return ['/bin/bash', str(script), action] + ([target] if target else [])

    def measure(label, commands, expected=None):
        times = []
        for i in range(args.samples):
            index = i % len(commands)
            then = time.perf_counter_ns()
            run(commands[index])
            times.append((time.perf_counter_ns() - then) / 1e6)
            if expected:
                actual = aero('list-workspaces', '--focused')
                if actual != expected[i % len(expected)]:
                    raise RuntimeError(f'{label}: expected {expected[i % len(expected)]}, got {actual}')
            time.sleep(0.08)  # Let callbacks settle outside the timed interval.
        ordered = sorted(times)
        result = dict(label=label, median_ms=statistics.median(times),
                      p95_ms=ordered[math.ceil(len(times) * .95) - 1],
                      min_ms=min(times), max_ms=max(times), samples_ms=times)
        results.append(result)
        print(f'{label}: median {result["median_ms"]:.1f} ms; p95 {result["p95_ms"]:.1f} ms', flush=True)

    previous = None
    try:
        # Preserve AeroSpace's native previous/current pair as well as our files.
        aero('workspace-back-and-forth')
        previous = aero('list-workspaces', '--focused')
        aero('workspace', start)
        for target, group in ((other, 'numbered'), (special, 'special')):
            # Initialize both shell history and native history for this same pair.
            run(shell('numbered', base))
            run(shell('numbered' if group == 'numbered' else 'special', target))
            run(shell('numbered', base))
            expected = [target, base]
            print(f'Comparing workspace {base} <-> {target}', flush=True)
            measure(f'{group}: native back-and-forth (Command-Tab command)',
                    [[cli, 'workspace-back-and-forth']], expected)
            # An even number of switches finishes at base.
            aero('workspace', base)
            measure(f'{group}: direct summon',
                    [[cli, 'summon-workspace', target], [cli, 'summon-workspace', base]], expected)
            if group == 'numbered':
                measure('numbered: history script (Option-number)',
                        [shell('numbered', target), shell('numbered', base)], expected)
                measure('numbered: history script (Option-backtick)',
                        [shell('previous-numbered')], expected)
            else:
                measure('special: history script (Option-letter)',
                        [shell('special', target)], expected)
                measure('special: history script (Option-Tab)',
                        [shell('toggle-special')], expected)
        measure('component: focused workspace query', [[cli, 'list-workspaces', '--focused']])
        measure('component: focused monitor query',
                [[cli, 'list-monitors', '--focused', '--format', '%{monitor-id}']])
        measure('component: empty Bash process', [['/bin/bash', '-c', ':']])
    finally:
        try:
            if previous and previous != start:
                aero('workspace', previous)
            aero('workspace', start)
            if focus:
                aero('focus', '--window-id', focus)
        finally:
            for path in state_dir.glob('monitor-*'):
                if path.is_file() and path.name not in saved:
                    path.unlink()
            for name, data in saved.items():
                (state_dir / name).write_bytes(data)
    report = dict(start_workspace=start, numbered_pair=[base, other],
                  special_pair=[base, special], samples_per_route=args.samples,
                  metric='process completion; excludes physical keypress and display repaint',
                  results=results)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(f'Restored workspace {start}. Report: {args.output}', flush=True)


if __name__ == '__main__':
    main()
