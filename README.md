# mac-dotfiles

Nix Flakes + nix-darwin + integrated Home Manager, with live-editable configuration
in the existing `.config/` tree. Homebrew continues to own the established tools
and applications; Nix initially supplies the missing Lua language server.

**Installed, validated and activated on this Mac (2026-10-26).**
System generation 1 is active. SketchyBar is installed but remains stopped.
See [audit and risks](docs/audit.md), [package inventory](docs/inventory.md), and
[validation results](docs/validation.md). No commits or pushes were made.

## What lives where

```
flake.nix / flake.lock            compatible stable 26.05 inputs, pinned revisions
hosts/macbook/settings.nix        username, home, checkout path, architecture
hosts/macbook/default.nix         nix-darwin + integrated Home Manager host
modules/darwin/                   Nix settings and conservative Homebrew inventory
modules/home/                    shared links/packages and separate Darwin links
modules/home/links.json           link inventory used by HM and the preflight
.config/                         existing editable application files
scripts/                         read-only checks and explicit backed-up link handoff
```

The checkout defaults to `~/dotfiles`, matching this Mac. Change
`dotfilesDirectory` in `hosts/macbook/settings.nix` to an **absolute runtime path**
when cloning elsewhere. It must stay outside `~/.config` and `/nix/store`.
The checkout must remain at that path after activation. Moving it requires
updating the setting and rebuilding. Existing Fish `cfg` and personal document/SDK
paths are intentionally preserved; adjust these yourself on a differently laid-out Mac.

Home Manager uses `config.lib.file.mkOutOfStoreSymlink` with that runtime string,
not `self`, a relative Nix path literal, or a store copy. Directory links expose
new files immediately and preserve script permissions. Nix owns the deployment
links; Git owns the mutable content. **Nix generations do not snapshot these
files.** Use Git to recover their previous contents. Nix module/generated system
files remain immutable and generation-managed.

## Fresh Mac bootstrap

Run these commands in **zsh** (the macOS default); Fish syntax differs. Review
installer scripts before executing. This workflow needs no preinstalled Brew,
npm, Home Manager or darwin-rebuild. On another working Mac, review and approve installation,
link handoff, and activation before running them.

1. Install Apple's tools and finish the GUI installation:

   ```sh
   xcode-select --install
   xcode-select -p
   ```

2. Install upstream multi-user Nix, using the maintained
   [official macOS installer](https://nixos.org/download/). Skip if installed:

   ```sh
   curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install -o /tmp/install-nix
   less /tmp/install-nix
   sh /tmp/install-nix
   ```

   Open a new zsh terminal, or load the daemon profile:

   ```sh
   . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
   nix --version
   ```

   This flake uses upstream Nix managed by nix-darwin. If you intentionally choose
   Determinate Nix instead, review its nix-darwin integration and set
   `nix.enable = false` before activation; do not let both manage the daemon.
   Installation, builds and activation succeeded on the audited macOS 27 Mac;
   application-specific GUI checks are listed in docs/validation.md.

3. Install Homebrew from its [official installer](https://brew.sh/) only if missing:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /tmp/install-homebrew
   less /tmp/install-homebrew
   /bin/bash /tmp/install-homebrew
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

   For an Intel Mac use `/usr/local/bin/brew` instead, and change host `system` to
   `x86_64-darwin` if still supported by the selected stable release. No automatic
   Homebrew installation is embedded in activation.

4. Clone using HTTPS so no SSH credentials are needed yet:

   ```sh
   git clone https://github.com/mrecinto/mac-dotfiles.git "$HOME/dotfiles"
   cd "$HOME/dotfiles"
   ```

   Review `hosts/macbook/settings.nix`: username, home, architecture, checkout.
   Editing tracked Nix files is enough; **new files must be `git add`ed** because
   flakes filter untracked Git files. Preserve stateVersion values on later updates.
   The fixed output name `macbook` works without changing the machine hostname.

5. Build and check before switching:

   ```sh
   nix --extra-experimental-features 'nix-command flakes' flake metadata --no-write-lock-file
   nix --extra-experimental-features 'nix-command flakes' flake check --no-build --no-write-lock-file
   nix --extra-experimental-features 'nix-command flakes' build --no-link .#darwinConfigurations.macbook.system
   ```

   These commands do not install the Homebrew inventory or activate links.
   Do not execute the generated `activate` script as a check: its clean-environment
   shebang discards a `checkActivation=1` environment flag and can activate the system.
   Once Python is available, `./scripts/validate.sh` additionally runs local tests and
   builds the HM activation package. Apple CLT Python works for the preflight/tests;
   Homebrew's Python can also run them.

6. Check destination ownership:

   ```sh
   python3 scripts/check-links.py
   ```

   Exit 0: ready. Exit 2: matching unmanaged links need a handoff. Exit 1: collision
   requiring manual inspection. The script does not assume that an unrelated config
   can be replaced. This Mac now has eleven HM-owned links; the initial migration
   found ten unmanaged matching links. On a clean Mac expect new targets. Apps that already generated config directories may need individual
   backups first. Do not point `~/.config` at this whole repository.

   **After reviewing the build and approving changes**, close affected apps and
   prepare existing matching links (unnecessary for a clean home):

   ```sh
   python3 scripts/check-links.py --backup-existing-links
   ```

   This moves only matching absolute symlinks to
   `~/.local/state/dotfiles/link-backups/<timestamp>/.config/...`. Their source
   contents are untouched. It refuses collisions before moving anything. HM can
   adopt identical existing links directly, but this explicit handoff preserves backups first. Activate
   immediately; paths are temporarily absent during this handoff.

7. First activation uses the **pinned** darwin-rebuild app from this flake:

   ```sh
   sudo nix --extra-experimental-features 'nix-command flakes' run .#darwin-rebuild -- switch --flake .#macbook
   ```

   If sudo cannot find Nix, replace `nix` with
   `/nix/var/nix/profiles/default/bin/nix`. Home Manager activates automatically
   as part of nix-darwin; do not separately run `home-manager switch` over these links.
   Afterward open a new terminal and check `type -a nix nvim fish node npm tinymist
   lua-language-server`. Fish's guarded conf.d appends Nix profiles and keeps the
   existing Brew/npm commands preferred. Default shell is not changed; run `fish`
   manually on a new Mac if desired.

8. Restore applications installed outside Brew, npm tools, accounts and permissions:

   - On a clean Mac, install Zen and Xournal++ with their official installers, or
     `brew install --cask zen` for Zen. The Homebrew Xournal++ cask is currently
     disabled; use [upstream macOS downloads](https://github.com/xournalpp/xournalpp/releases).
     Existing installations are not adopted or overwritten by activation.
   - Restore the global npm prefix/packages explicitly (not needed on this Mac):

     ```sh
     mkdir -p "$HOME/.npm-global"
     npm config set prefix "$HOME/.npm-global"
     npm install -g @openai/codex@0.164.0 @picoxr/pico-cli@0.6.1
     export PATH="$HOME/.npm-global/bin:$PATH"
     ```

     Brew installs Node/npm during activation. The versions above reproduce the
     observed npm requests; auth, credentials and server state require sign-in.
     Project package.json/lockfiles remain owned by each project. No global npm
     installer runs during Nix activation.
   - Restore Git identity (the existing `~/.gitconfig` is intentionally unmanaged):

     ```sh
     git config --global user.name mrecinto
     git config --global user.email 95442899+mrecinto@users.noreply.github.com
     ```

     Restore SSH keys/signing/credential helpers securely, never into this repository.
   - Start Neovim, restore the existing lazy.nvim plugin lock with `:Lazy restore`,
     and run `:checkhealth`. Parser/native builds and preview plugin downloads
     still use the network; Nix does not lock these runtime downloads.
   - Grant AeroSpace Accessibility and requested AppleScript Automation. Review
     Karabiner Input Monitoring/driver prompts and enable the existing rule in its UI.
     Restore document access, Wacom/Logitech permissions, browser/app accounts,
     Android/PICO SDKs, TeX if used, personal documents and `.local/bin` tools.
     See the audit for the concrete dependencies and non-Brew application inventory.

## Daily editing

```sh
nvim ~/dotfiles/.config/sketchybar/sketchybarrc
sketchybar --reload
```

No Nix rebuild for normal `.config` edits, scripts, new files in linked directories,
Yazi templates, or lazy.nvim specs/lockfile edits. Apps still need their own reload:
AeroSpace `aerospace reload-config`; tmux prefix then `R`; Fish restart or
`source ~/.config/fish/config.fish`; Neovim restart. Commit desired content with Git.
Executable plugin scripts need `chmod +x` and executable Git mode.

SketchyBar's starter is a single label with a 32px top offset; adjust placement for
your screens/notch. It is installed via Brew but **not started automatically**.
After first activation, run `sketchybar` in a terminal to test; stop with Ctrl-C.
Only when satisfied, opt in to startup with `brew services start sketchybar`.
`sketchybar --reload` requires a running bar. New scripts under `plugins/` are live.
No menu bar hiding, prebuilt theme, or space integration is configured. Its upstream
“Displays have separate Spaces” requirement conflicts with your AeroSpace note:
review that manually before enabling it. No extra permissions are required by the
single-label starter; future plugins may request access according to their commands.

SketchyBar follows the main display's wallpaper automatically. Its hidden
`wallpaper_theme` item checks every second and on wake, runs Matugen only when
the image path or modification time changes, and reloads the bar with the new
palette. Change wallpapers in System Settings as usual. Matugen is managed in
`modules/home/packages.nix`; the palette template and fallback colors live in
`.config/sketchybar/theme/`. Generated colors and the compiled AppKit wallpaper
helper live in `~/Library/Caches/sketchybar-theme` (or `$XDG_CACHE_HOME`). If the
wallpaper isn't a readable image, the last working palette stays active. The
palette follows the main display; changing displays/Spaces with distinct images
may change it. Animated wallpaper frames aren't sampled. To force regeneration,
delete the cache's `signature` file and wait for the next check.

## Packages and structural changes

- Add Brew apps/formulae/taps in `modules/darwin/homebrew.nix`. Existing tools remain
  there to avoid version changes; Nix is a good later owner for CLI/LSP dependencies
  when you choose to migrate them. GUI/cask apps, Zathura's tap and Node remain Brew.
- Add Nix packages in `modules/home/packages.nix`. Inspect `type -a` first and choose
  an owner before adding a duplicate. Do not automatically uninstall its Brew copy.
- To add a config directory, create `.config/NAME`, add its name to the appropriate
  shared/Darwin list in `modules/home/links.json`, stage both, run the preflight,
  then rebuild. New files inside an already linked directory need no rebuild.
- Keep secrets and mutable per-machine state outside the checkout. A flake source
  can enter the world-readable Nix store even when a file is not used by a module.
  Do not `git add` credentials, fish_variables, backups, or private settings.
- Future Linux: import `self.homeModules.default` from a separate Linux host with
  Home Manager, set identity/path, and install the Linux package set. Review the
  current macOS commands embedded in Neovim/Yazi; see [audit](docs/audit.md).

For Nix package or system/link changes:

```sh
./scripts/validate.sh
sudo darwin-rebuild switch --flake .#macbook
```

To update pinned dependencies deliberately:

```sh
nix flake update
# or: nix flake update nixpkgs home-manager nix-darwin
./scripts/validate.sh
git diff -- flake.lock
sudo darwin-rebuild switch --flake .#macbook
# Review and commit flake.lock and the intended source edits yourself.
```

Do not change home.stateVersion/system.stateVersion as routine upgrades. Brew
upgrades/auto-updates and cleanup are disabled during activation. Brew and npm
versions are not pinned by flake.lock, and installing missing packages can still
update dependencies. Review Brew changes. Unlisted applications stay installed.

## Recovery and troubleshooting

- First switch fails: inspect output before retrying. A system activation can be
  partially applied before HM/Brew fails; it is not a cross-package-manager transaction.
  If links were handed off but HM did not create replacements, restore each backed-up
  symlink with `mv BACKUP/.config/NAME ~/.config/NAME` **only after checking the target
  is absent**. The nested Karabiner rule restores to its original nested path.
  If HM already made a link, inspect and back it up before restoring an older link.
- First nix-darwin switch may refuse pre-existing `/etc` files, commonly
  `/etc/nix/nix.conf`, `/etc/zshrc`, or `/etc/zprofile`. Inspect its exact message,
  make timestamped copies outside this repo, and move only the named conflicting
  file after review. Do not add force/overwrite settings to bypass the check.
- Later Nix rollback: `sudo darwin-rebuild switch --rollback`. Inspect generations
  with `sudo nix-env --profile /nix/var/nix/profiles/system --list-generations`.
  This rolls back Nix-managed state/links, not live content, Homebrew/npm installs,
  permissions or app data. Recover dotfile contents separately with Git.
- `file ... not found` in a Git flake: stage new Nix/JSON sources with `git add`.
- Config points nowhere: verify `dotfilesDirectory`, `readlink ~/.config/APP`, and
  `python3 scripts/check-links.py`. Keep the checkout available; do not copy configs
  into the store as a workaround.
- Missing Nix commands in Fish: open a new session, check the guarded conf.d file
  and profile directories. zsh can source the daemon profile shown above.
- Package conflicts: use `type -a TOOL`, `brew list --versions TOOL` and `npm list -g
  --depth=0`. Keep npm's prefix user-writable; avoid `sudo npm install -g`.
- macOS updates can affect Nix users/daemon mounts and GUI permissions. Consult the
  [Nix installer documentation](https://nixos.org/download/) and
  [nix-darwin documentation](https://github.com/nix-darwin/nix-darwin) for the exact
  reported error. Do not blindly reinstall or delete `/nix`.

Before migrating to another Mac, commit your intended configuration and flake.lock
locally, then push when you choose. Clone that revision, edit host settings, build,
inspect collisions, switch, and finish manual restoration. No automatic commit,
push, service enablement, default-shell change or destructive cleanup is included.

SketchyBar's Waybar-style layout uses ten AeroSpace workspace buttons (including
empty workspaces), a centered focused window title, and a wallpaper-colored
vertical gradient matching the original CSS opacity stops. Workspace highlighting updates immediately through AeroSpace callbacks;
occupancy/app metadata refreshes every five seconds and window titles every second. ImageMagick renders the gradient into
the theme cache on reload. The power icon opens System Settings; it does not
shut down the Mac. Linux tray and urgent-window signals have no direct mapping
in this setup.

The `✦` button after workspace 10 opens a menu for W, A, S, D, I, and O,
with each workspace's app names and a checkmark on the focused workspace.
It displays the letter while a special workspace is focused. Selecting a row
uses the same summon/return behavior as the Option-letter keyboard shortcuts;
selecting the current special workspace returns to its numbered origin.

Workspace shortcuts keep per-monitor history through `workspace.sh`, which
executes the standard-library Python helper `workspace.py`. It uses one connection
to AeroSpace's documented local socket API for live focus/monitor lookup and the
switch, avoiding repeated CLI launches. A kernel lock serializes history updates;
the existing four-line history files remain compatible. No extra daemon is needed.
Measured command timings are in [the before/after report](docs/benchmarks/workspace-latency-optimized.md).

Option-[ and Option-] cycle backward/forward through occupied numbered
workspaces on the focused monitor, skipping empty workspaces and wrapping.
Special workspaces remain accessible through their Option-letter shortcuts.

Option-Control-Shift-1 through 9 moves all windows from the current workspace
to that numbered workspace and follows them; 0 targets workspace 10. This also
works from a special workspace. Existing destination windows remain there.
The previously focused window regains focus, but AeroSpace may rearrange splits,
window order, and sizes because it moves windows individually.

Wallpaper theming normalizes the image to a small cached PNG before invoking
Matugen, so wallpapers with mismatched extensions (such as JPEGs named `.png`)
work without modifying the original file.

Wallpaper palettes are cached by image contents, template, and Matugen version
in the theme cache's `palettes/` directory. Switching back reuses the saved palette;
only unseen/changed images or generation settings run Matugen again. Detection
takes up to one second. Gradient images are cached too, avoiding regeneration
on a cached wallpaper switch.

Wallpaper colors also generate `ghostty.conf` and `zen.css` in the theme cache.
Ghostty includes the generated background/foreground/cursor/selection colors over
its Catppuccin ANSI palette; reload via Command-Shift-comma if scripting reload
is unavailable. The watcher requests Ghostty's `reload_config` action automatically.
Run `python3 scripts/install-zen-wallpaper.py` after setting up a new Mac to link
the generated CSS into the installed Zen profile. Existing userChrome and user.js
files are preserved and backed up before edits. Restart Zen to load changed CSS;
this themes browser UI, not page contents.

Ghostty follows macOS light/dark appearance using two generated theme files.
The dark variant uses the bar palette; the light variant is generated from the
wallpaper accent and cached by accent/template/version. Zen and SketchyBar keep
their existing dark palettes.

SketchyBar draws its gradient inside each monitor's bar bounds, preventing
background strips from spilling onto adjacent displays with different positions.
Revealing the native macOS menu bar hides SketchyBar only on that monitor; other
monitors keep their bars. Visibility resets when monitors change or the Mac wakes.
