import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


@unittest.skipUnless(shutil.which('sw_vers'), 'macOS wallpaper watcher')
class WallpaperCache(unittest.TestCase):
    def test_revisiting_image_reuses_palette_and_template_change_invalidates(self):
        repo = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = root / 'config'
            shutil.copytree(repo / '.config/sketchybar', config)
            # This test isolates wallpaper cache behavior from app integrations.
            (config / 'helpers/app-colors.sh').write_text('#!/bin/sh\nexit 0\n')
            cache = root / 'cache/sketchybar-theme'
            cache.mkdir(parents=True)
            bins = root / '.nix-profile/bin'
            bins.mkdir(parents=True)
            calls = root / 'calls'
            env = dict(os.environ, HOME=tmp, XDG_CACHE_HOME=str(root / 'cache'),
                       CONFIG_DIR=str(config), TEST_CALLS=str(calls),
                       TEST_SELECTED=str(root / 'selected'))

            def executable(path, body):
                path.write_text('#!/bin/sh\nset -eu\n' + body)
                path.chmod(0o755)

            version = subprocess.check_output(
                ['cksum'], input=(config / 'helpers/wallpaper.swift').read_bytes()
            ).decode().split()[0]
            executable(cache / ('wallpaper-' + version), 'cat "$TEST_SELECTED"\n')
            executable(bins / 'magick', 'for last do :; done\nprintf png > "$last"\n')
            executable(bins / 'matugen', '''
if [ "$1" = --version ]; then echo test-version; exit; fi
printf 'generate\\n' >> "$TEST_CALLS"
out=$(sed -n "s/^output_path = '\\(.*\\)'$/\\1/p" "$2")
cat > "$out" <<'PALETTE'
BACKGROUND=0xd911140f
ON_BACKGROUND=0xffe1e4da
PRIMARY=0xffa4d396
ON_PRIMARY=0xff10380c
SURFACE_VARIANT=0xff43483f
SURFACE_TINT=0xffa4d396
ERROR=0xffffb4ab
PALETTE
''')
            executable(bins / 'sketchybar', 'printf "apply\\n" >> "$TEST_CALLS"\n')
            images = [root / 'one.png', root / 'two.png']
            for i, image in enumerate(images):
                image.write_text(str(i))

            def select(image):
                (root / 'selected').write_text(str(image))
                subprocess.run(['/bin/sh', str(config / 'plugins/wallpaper.sh')],
                               env=env, check=True, capture_output=True)

            select(images[0])
            select(images[0])  # Unchanged wallpaper does nothing.
            select(images[1])
            select(images[0])  # Previously seen image bypasses generation.
            self.assertEqual(calls.read_text().splitlines(),
                             ['generate', 'apply', 'generate', 'apply', 'apply'])
            with (config / 'theme/colors.template').open('a') as template:
                template.write('\n')
            select(images[0])
            self.assertEqual(calls.read_text().splitlines()[-2:], ['generate', 'apply'])
