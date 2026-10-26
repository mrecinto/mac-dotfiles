#!/usr/bin/env python3
"""Read-only by default. Explicit --backup-existing-links prepares an HM handoff."""
import argparse
import datetime
import json
import os
from pathlib import Path
import sys


def inspect(repo, home):
    manifest = json.loads((repo / 'modules/home/links.json').read_text())
    names = manifest['shared'] + manifest['darwin']
    problems, handoff = [], []
    for name in names:
        source = repo / '.config' / name
        target = home / '.config' / name
        if not source.exists():
            problems.append(f'MISSING SOURCE: {source}')
            continue
        # Refuse redirected parents, including a ~/.config -> checkout symlink.
        for parent in target.parents:
            if parent == home:
                break
            if parent.is_symlink():
                problems.append(f'REDIRECTED PARENT: {parent} -> {os.readlink(parent)}')
                break
        else:
            problems.append(f'TARGET OUTSIDE HOME: {target}')
        if not os.path.lexists(target):
            print(f'NEW: {target} -> {source}')
        elif target.is_symlink() and target.resolve() == source.resolve():
            if os.readlink(target).startswith('/nix/store/') and '-home-manager-files/' in os.readlink(target):
                print(f'HM LINK (same source): {target}')
            elif not os.path.isabs(os.readlink(target)):
                problems.append(f'RELATIVE LINK: {target}; back it up manually before handoff')
            else:
                print(f'HANDOFF: {target} -> {os.readlink(target)}')
                handoff.append(target)
        else:
            problems.append(f'COLLISION: {target} (expected {source})')
    return problems, handoff


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--home', type=Path, default=Path.home())
    parser.add_argument('--backup-existing-links', action='store_true',
                        help='MOVE ONLY matching unmanaged symlinks to a timestamped backup; obtain approval first')
    args = parser.parse_args()
    repo, home = args.repo.expanduser().resolve(), args.home.expanduser().resolve()
    if repo == home / '.config' or home / '.config' in repo.parents:
        parser.error('checkout must be outside ~/.config')
    problems, handoff = inspect(repo, home)
    if problems:
        print('\n'.join(problems), file=sys.stderr)
        print('Resolve collisions manually; no links moved.', file=sys.stderr)
        return 1
    if handoff and not args.backup_existing_links:
        print(f'{len(handoff)} existing links need a backed-up handoff before first HM activation.')
        return 2
    if handoff:
        stamp = datetime.datetime.now().strftime('%Y%m%dT%H%M%S%f')
        backup = home / '.local/state/dotfiles/link-backups' / stamp
        # No forced overwrite, unlink, or automatic treatment of unrelated configs.
        for target in handoff:
            relative = target.relative_to(home)
            destination = backup / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            target.rename(destination)
        print(f'Matching symlinks moved to {backup}')
        print('Activate immediately. To abort, move each saved symlink back to its original path.')
    else:
        print('No unmanaged matching links need a handoff.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
