"""Exercise the handoff's safety using disposable homes, never the real ~/.config."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/check-links.py'


class LinkHandoff(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        self.repo, self.home = root / 'checkout', root / 'home'
        (self.repo / 'modules/home').mkdir(parents=True)
        (self.repo / 'modules/home/links.json').write_text(json.dumps({'shared': ['fish'], 'darwin': []}))
        self.source = self.repo / '.config/fish'
        self.source.mkdir(parents=True)
        (self.source / 'config.fish').write_text('# custom config\n')
        (self.home / '.config').mkdir(parents=True)
        self.target = self.home / '.config/fish'

    def run_check(self, *args):
        return subprocess.run(['python3', str(SCRIPT), '--repo', str(self.repo),
                               '--home', str(self.home), *args], capture_output=True, text=True)

    def test_new_home_is_ready(self):
        self.assertEqual(self.run_check().returncode, 0)
        self.assertFalse(self.target.exists())

    def test_read_only_matching_link(self):
        self.target.symlink_to(self.source)
        self.assertEqual(self.run_check().returncode, 2)
        self.assertTrue(self.target.is_symlink())
        self.assertFalse((self.home / '.local').exists())

    def test_backup_preserves_symlink_and_source(self):
        self.target.symlink_to(self.source)
        self.assertEqual(self.run_check('--backup-existing-links').returncode, 0)
        backups = list((self.home / '.local/state/dotfiles/link-backups').glob('*/.config/fish'))
        self.assertEqual(len(backups), 1)
        self.assertTrue(backups[0].is_symlink())
        self.assertEqual(backups[0].resolve(), self.source.resolve())
        self.assertFalse(self.target.is_symlink())
        self.assertEqual((self.source / 'config.fish').read_text(), '# custom config\n')

    def test_real_directory_is_never_moved(self):
        self.target.mkdir()
        self.assertEqual(self.run_check('--backup-existing-links').returncode, 1)
        self.assertTrue(self.target.is_dir())
        self.assertFalse((self.home / '.local').exists())

    def test_unrelated_or_broken_symlink_is_never_moved(self):
        self.target.symlink_to(self.home / 'unrelated-missing')
        self.assertEqual(self.run_check('--backup-existing-links').returncode, 1)
        self.assertTrue(self.target.is_symlink())

    def test_relative_link_requires_manual_review(self):
        self.target.symlink_to(os.path.relpath(self.source, self.target.parent))
        self.assertEqual(self.run_check('--backup-existing-links').returncode, 1)
        self.assertTrue(self.target.is_symlink())

    def test_collision_prevents_all_moves(self):
        self.target.symlink_to(self.source)
        manifest = self.repo / 'modules/home/links.json'
        manifest.write_text(json.dumps({'shared': ['fish', 'nvim'], 'darwin': []}))
        (self.repo / '.config/nvim').mkdir()
        (self.home / '.config/nvim').mkdir()
        self.assertEqual(self.run_check('--backup-existing-links').returncode, 1)
        self.assertTrue(self.target.is_symlink())
        self.assertFalse((self.home / '.local').exists())

    def test_redirected_parent_blocks_handoff(self):
        (self.home / '.config').rmdir()
        (self.home / '.config').symlink_to(self.repo / '.config')
        self.assertEqual(self.run_check('--backup-existing-links').returncode, 1)
        self.assertTrue(self.source.is_dir())


if __name__ == '__main__':
    unittest.main()
