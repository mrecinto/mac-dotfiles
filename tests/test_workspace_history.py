"""History semantics and AeroSpace IPC, without touching the real desktop."""
import importlib.util
import json
from pathlib import Path
import socket
import struct
import tempfile
import threading
import unittest

SOURCE = Path(__file__).resolve().parents[1] / '.config/aerospace/scripts/workspace.py'
spec = importlib.util.spec_from_file_location('workspace', SOURCE)
workspace = importlib.util.module_from_spec(spec)
spec.loader.exec_module(workspace)


class FakeAeroSpace:
    def __init__(self, current='2', monitor='1'):
        self.current, self.monitor = current, monitor
        self.occupied = ['2', '5', '10', 'W']
        self.moves = []
        self.fail = False

    def command(self, *args):
        if args[:2] == ('list-workspaces', '--focused'):
            return self.current + '|' + self.monitor
        if args[:2] == ('list-workspaces', '--monitor'):
            assert args[2] == self.monitor
            return '\n'.join(self.occupied)
        if args[0] == 'summon-workspace':
            if self.fail:
                raise RuntimeError('simulated switch failure')
            self.current = args[1]
            self.moves.append(args[1])
            return ''
        raise AssertionError(args)


class HistoryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.client = FakeAeroSpace()

    def navigate(self, action, target=''):
        workspace.validate(action, target)
        workspace.navigate(self.client, action, target, str(self.directory))

    def history(self, monitor='1'):
        return (self.directory / ('monitor-' + monitor)).read_text().splitlines()

    def test_numbered_previous_and_external_switch(self):
        self.navigate('numbered', '5')
        self.assertEqual(self.history()[:2], ['5', '2'])
        self.navigate('previous-numbered')
        self.assertEqual(self.client.current, '2')
        self.assertEqual(self.history()[:2], ['2', '5'])
        self.client.current = '10'  # Command-Tab or bar click bypassed our script.
        self.navigate('previous-numbered')
        self.assertEqual(self.client.current, '2')
        self.assertEqual(self.history()[:2], ['2', '10'])

    def test_special_origin_survives_switching_letters(self):
        self.navigate('special', 'W')
        self.navigate('special', 'A')
        self.navigate('special', 'A')  # Same letter returns to origin.
        self.assertEqual(self.client.current, '2')
        self.assertEqual(self.history()[2:], ['A', '2'])
        self.navigate('toggle-special')
        self.assertEqual(self.client.current, 'A')
        self.navigate('toggle-special')
        self.assertEqual(self.client.current, '2')

    def test_new_origin_updates_special_return(self):
        self.navigate('special', 'W')
        self.navigate('numbered', '5')
        self.navigate('toggle-special')
        self.navigate('toggle-special')
        self.assertEqual(self.client.current, '5')
        self.assertEqual(self.history()[2:], ['W', '5'])

    def test_monitor_history_is_independent(self):
        self.navigate('numbered', '5')
        first = self.history()
        self.client.monitor, self.client.current = '2', '3'
        self.navigate('special', 'S')
        self.assertEqual(self.history(), first)
        self.assertEqual(self.history('2'), ['3', '', 'S', '3'])

    def test_occupied_skips_and_wraps_both_directions(self):
        for current, direction, expected in [('2', 'next', '5'), ('10', 'next', '2'),
                                              ('2', 'prev', '10'), ('4', 'prev', '2'),
                                              ('W', 'next', '2'), ('W', 'prev', '10')]:
            with self.subTest(current=current, direction=direction):
                self.client.current = current
                self.navigate('occupied', direction)
                self.assertEqual(self.client.current, expected)

    def test_empty_or_only_current_does_not_switch(self):
        for occupied in ([], ['2']):
            self.client.occupied = occupied
            self.navigate('occupied', 'next')
        self.assertEqual(self.client.moves, [])

    def test_failed_switch_does_not_modify_saved_history(self):
        self.navigate('numbered', '5')
        before = self.history()
        self.client.fail = True
        with self.assertRaises(RuntimeError):
            self.navigate('special', 'W')
        self.assertEqual(self.history(), before)
        self.assertFalse(list(self.directory.glob('monitor-*.*')))

    def test_invalid_saved_state_is_sanitized(self):
        (self.directory / 'monitor-1').write_text('bogus\n100\nZ\n999\n')
        self.navigate('numbered', '2')
        self.assertEqual(self.history(), ['2', '', '', ''])
        self.assertEqual(self.client.moves, [])

    def test_missing_history_toggle_is_noop(self):
        self.navigate('toggle-special')
        self.navigate('previous-numbered')
        self.assertEqual(self.client.moves, [])

    def test_invalid_targets_are_rejected(self):
        for action, target in [('numbered', '0'), ('special', 'X'), ('occupied', 'bad'),
                               ('unknown', ''), ('toggle-special', 'W')]:
            with self.assertRaises(ValueError):
                workspace.validate(action, target)


class ProtocolTests(unittest.TestCase):
    def test_fragmented_frames_connection_reuse_and_command_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            path = str(Path(directory) / 'server.sock')
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as listener:
                listener.bind(path)
                listener.listen(1)
                errors, requests = [], []

                def serve():
                    try:
                        connection, _ = listener.accept()
                        with connection:
                            connection.settimeout(2)

                            def exact(n):
                                data = b''
                                while len(data) < n:
                                    chunk = connection.recv(n - len(data))
                                    if not chunk:
                                        raise EOFError()
                                    data += chunk
                                return data

                            self.assertEqual(struct.unpack('<I', exact(4))[0], 1)
                            connection.sendall(struct.pack('<I', 1))
                            for exit_code, stdout in [(0, '2|1\n'), (0, ''), (1, '')]:
                                size = struct.unpack('<I', exact(4))[0]
                                requests.append(json.loads(exact(size)))
                                response = json.dumps(dict(exitCode=exit_code, stdout=stdout,
                                                           stderr='failed' if exit_code else '')).encode()
                                frame = struct.pack('<I', len(response)) + response
                                for byte in frame:
                                    connection.sendall(bytes([byte]))
                    except BaseException as error:
                        errors.append(error)

                server = threading.Thread(target=serve, daemon=True)
                server.start()
                client = workspace.AeroSpace(path)
                try:
                    self.assertEqual(client.command('list-workspaces', '--focused'), '2|1')
                    self.assertEqual(client.command('summon-workspace', '5'), '')
                    with self.assertRaisesRegex(RuntimeError, 'failed'):
                        client.command('summon-workspace', 'W')
                finally:
                    client.close()
                    server.join(timeout=3)
                self.assertFalse(server.is_alive())
                self.assertEqual(errors, [])
                self.assertEqual(len(requests), 3)
                self.assertEqual(requests[1]['args'], ['summon-workspace', '5'])


if __name__ == '__main__':
    unittest.main()
