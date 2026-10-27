#!/usr/bin/python3
"""Workspace history using one connection to AeroSpace's public socket API.

Protocol: https://nikitabobko.github.io/AeroSpace/guide#socket-protocol
No daemon or cached focus state: each invocation reads live focus under a lock.
"""
import fcntl
import json
import os
import pwd
import socket
import struct
import sys

NUMBERED = tuple(str(n) for n in range(1, 11))
SPECIAL = ('W', 'A', 'S', 'D', 'I', 'O')


class AeroSpace:
    def __init__(self, path):
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.socket.settimeout(5)
        try:
            self.socket.connect(path)
            self.socket.sendall(struct.pack('<I', 1))
            if self.read_number() != 1:
                raise RuntimeError('Unsupported AeroSpace socket protocol')
        except BaseException:
            self.close()
            raise

    def close(self):
        self.socket.close()

    def read_exact(self, count):
        data = bytearray()
        while len(data) < count:
            chunk = self.socket.recv(count - len(data))
            if not chunk:
                raise ConnectionError('AeroSpace closed the connection')
            data.extend(chunk)
        return data

    def read_number(self):
        return struct.unpack('<I', self.read_exact(4))[0]

    def command(self, *args):
        request = json.dumps(dict(args=args, stdin='', windowId=None, workspace=None)).encode()
        self.socket.sendall(struct.pack('<I', len(request)) + request)
        length = self.read_number()
        if length > 8 * 1024 * 1024:
            raise RuntimeError('AeroSpace reply is too large')
        answer = json.loads(self.read_exact(length))
        if answer['exitCode'] != 0:
            raise RuntimeError(answer.get('stderr') or 'AeroSpace command failed')
        return answer['stdout'].strip()


def validate(action, target):
    if action == 'numbered' and target in NUMBERED:
        return
    if action == 'special' and target in SPECIAL:
        return
    if action == 'occupied' and target in ('next', 'prev'):
        return
    if action in ('toggle-special', 'previous-numbered') and not target:
        return
    raise ValueError('Invalid workspace action or destination')


def navigate(client, action, target, state_dir):
    """Called under the process lock; failed switches never commit new history."""
    focused = client.command('list-workspaces', '--focused', '--format', '%{workspace}|%{monitor-id}')
    current, separator, monitor = focused.partition('|')
    if not separator or not current or not monitor.isdigit():
        raise RuntimeError('Invalid focused workspace/monitor reply')
    state_path = os.path.join(state_dir, 'monitor-' + monitor)
    try:
        with open(state_path) as saved:
            values = saved.read().splitlines()
    except FileNotFoundError:
        values = []
    values = (values + [''] * 4)[:4]
    numbered, previous, last_special, special_return = values
    numbered = numbered if numbered in NUMBERED else ''
    previous = previous if previous in NUMBERED else ''
    last_special = last_special if last_special in SPECIAL else ''
    special_return = special_return if special_return in NUMBERED else ''

    # Synchronize history if focus changed through Command-Tab or a bar click.
    if current in NUMBERED and numbered != current:
        previous, numbered = numbered or previous, current

    if action == 'occupied':
        occupied = set(client.command('list-workspaces', '--monitor', monitor, '--empty', 'no').splitlines())
        step = 1 if target == 'next' else -1
        index = NUMBERED.index(current) if current in NUMBERED else (-1 if step == 1 else 10)
        target = next((NUMBERED[(index + step * n) % 10] for n in range(1, 11)
                       if NUMBERED[(index + step * n) % 10] in occupied), '')
        if not target:
            return
        action = 'numbered'

    destination = ''
    if action == 'numbered':
        destination = target
        if target != current:
            if numbered and numbered != target:
                previous = numbered
            numbered = target
    elif action == 'special':
        if current == target:
            destination = special_return
        else:
            destination = target
            if current in NUMBERED:
                special_return = current
            last_special = target
    elif action == 'toggle-special':
        if current in SPECIAL:
            destination = special_return
        elif current in NUMBERED and last_special:
            destination = last_special
            special_return = current
    elif action == 'previous-numbered' and previous:
        destination = previous
        numbered, previous = previous, numbered

    if destination and destination != current:
        client.command('summon-workspace', destination)

    updated = [numbered, previous, last_special, special_return]
    if updated != values:
        temporary = state_path + '.' + str(os.getpid())
        try:
            with open(temporary, 'w') as saved:
                saved.write('\n'.join(updated) + '\n')
            os.replace(temporary, state_path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)


def main():
    if len(sys.argv) not in (2, 3):
        raise ValueError('Expected workspace action and optional destination')
    action, target = sys.argv[1], sys.argv[2] if len(sys.argv) == 3 else ''
    validate(action, target)
    user = pwd.getpwuid(os.getuid()).pw_name
    state_dir = '/tmp/aerospace-workspace-state-' + user
    os.makedirs(state_dir, mode=0o700, exist_ok=True)
    # Kernel lock releases on exit/crash. Serialize before reading live focus,
    # so rapid keypresses cannot make decisions using pre-lock stale state.
    descriptor = os.open(os.path.join(state_dir, '.history.lock'), os.O_CREAT | os.O_RDWR, 0o600)
    with os.fdopen(descriptor, 'r+') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        client = AeroSpace('/tmp/bobko.aerospace-' + user + '.sock')
        try:
            navigate(client, action, target, state_dir)
        finally:
            client.close()


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        print('workspace: ' + str(error), file=sys.stderr)
        sys.exit(1)
