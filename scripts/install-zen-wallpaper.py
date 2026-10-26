#!/usr/bin/env python3
"""Connect Zen's installed release profile to the generated wallpaper CSS."""
import configparser
from datetime import datetime
from pathlib import Path
import shutil

root = Path.home() / 'Library/Application Support/zen'
profiles = configparser.ConfigParser()
profiles.read(root / 'profiles.ini')
installed = [profiles[s]['Default'] for s in profiles.sections()
             if s.startswith('Install') and profiles.has_option(s, 'Default')]
if len(set(installed)) != 1:
    raise SystemExit('Cannot identify a single installed Zen profile; no changes made.')
profile = root / installed[0]
if not profile.is_dir():
    raise SystemExit('Zen profile is missing; no changes made.')
chrome = profile / 'chrome'
chrome.mkdir(exist_ok=True)
cache = Path.home() / 'Library/Caches/sketchybar-theme/zen.css'
link = chrome / 'wallpaper.css'
if link.exists() or link.is_symlink():
    if not link.is_symlink() or link.resolve() != cache:
        raise SystemExit('wallpaper.css already exists with another source; no overwrite.')
else:
    link.symlink_to(cache)


def update(path, text):
    old = path.read_text() if path.exists() else ''
    if old == text:
        return
    if path.exists():
        backup = path.with_name(path.name + '.before-wallpaper-' + datetime.now().strftime('%Y%m%d%H%M%S'))
        shutil.copy2(path, backup)
    path.write_text(text)

css = chrome / 'userChrome.css'
old = css.read_text() if css.exists() else ''
line = '@import url("wallpaper.css");'
if line not in old:
    update(css, line + '\n' + old)
prefs = profile / 'user.js'
old = prefs.read_text() if prefs.exists() else ''
line = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
if line not in old:
    update(prefs, old + '\n// Load the generated wallpaper UI theme.\n' + line + '\n')
print('Installed wallpaper CSS in:', profile)
print('Restart Zen to apply the UI colors. Web pages are unchanged.')
