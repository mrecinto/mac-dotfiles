# Validation and activation — 2026-10-26

## Current result

Upstream multi-user Nix installed successfully (installer/CLI 2.35.4). Both Nix
builds and the normal nix-darwin switch succeeded. System generation 1 is active:
`/run/current-system` and `/nix/var/nix/profiles/system` select
`/nix/store/9g820ncrwms59363csffylcaxnk2d335-darwin-system-26.05.d31953c`.
The pinned stable system/daemon uses Nix 2.34.9+1; the installer default profile
still supplies CLI 2.35.4. Both profiles are visible on Fish's PATH.

Home Manager generation:
`/nix/store/s8ziaavg4xmx9p2qzxhr228hdylgg3mh-home-manager-generation`.
All eleven deployed config links resolve to the existing mutable checkout.
No automatic Git commit or push was performed. Original Fish/Xournal++ edits
remain unstaged, as before migration.

## Checks that passed

- All ten Nix files parsed with Nix itself (also independently with Tree-sitter).
- `nix flake metadata --no-write-lock-file` consumed the supplied lock successfully.
- `nix flake check --no-build --no-write-lock-file`: all evaluations passed,
  including the complete Darwin system and integrated Home Manager generation.
- Both `checks.aarch64-darwin.home` and `darwinConfigurations.macbook.system`
  built successfully without activation using `./scripts/validate.sh`.
- Eight disposable-home tests cover fresh targets, read-only inspection, source
  preservation, backup, refusal of real directories/unrelated/broken/relative
  links/redirected parents, and all-or-nothing collision preflight.
- Fish, Bash, POSIX sh, TOML, JSON, XML and Neovim Lua syntax checks passed.
  Lua was compiled without executing the existing plugins or downloading them.
- Normal `sudo nix ... run .#darwin-rebuild -- switch --flake .#macbook
  --no-write-lock-file` completed with exit 0, including Homebrew and Home Manager.
- Post-activation link preflight exits 0: all eleven are generation-owned and
  resolve to the expected repo files. A newly created executable file under the
  repo's SketchyBar directory was immediately readable/executable via ~/.config;
  the generated check file was removed afterward.
- Yazi fix-xopp restored the existing template to a disposable empty .xopp file.
- Lua language server executes and reports 3.18.1. Fish resolves Git, Neovim,
  Fish, Node and npm from Homebrew after the startup PATH fix.
- AeroSpace responds: focused workspace S, monitor 1 (ZOWIE XL LCD). No workspace
  switching, config reload, or mouse/focus behavior changes were performed.
- Before/after Homebrew JSON comparison: **no existing formula/cask version changed
  and no installed formula was removed**. Only sketchybar 2.24.1 was added, along
  with its tap. `brew services list` shows sketchybar `none` (stopped).
- Existing executable modes preserved; new scripts executable. Git whitespace checks
  pass. Remote and branch/history are preserved.

## Activation incident and recovery

After successful builds, an intended check-only invocation executed the generated
activation script through `sudo env checkActivation=1 .../activate`. The script's
`#!/usr/bin/env -i .../bash` shebang discarded the flag, so it activated rather than
only checking. This was reported immediately when detected. The user had granted
standing approval to proceed, but the command did not behave as described.

The first activation set up /etc, Nix launchd integration, default SSH host keys,
Homebrew/SketchyBar and Home Manager. HM adopted the ten matching existing links
before the planned link-backup step. Source configuration contents remained in
the checkout unchanged; no unrelated configuration collisions were overwritten.
A subsequent normal nix-darwin switch completed and recorded system generation 1.

Recovery information:

- `/etc/bashrc.backup-before-nix` and `/etc/zshrc.backup-before-nix`: actual
  installer-created copies before installation.
- nix-darwin automatically saved replaced recognized /etc files as
  `*.before-nix-darwin` (including the Nix installer configuration). Inspect these
  before manual recovery; do not delete them blindly.
- `backups/original-config-links-20261026/` (Git-ignored) contains **reconstructed
  recovery symlinks from the initial audit**, a JSON target inventory, and copies
  of the two installer shell backups. They are not moved original symlinks and
  contain no copies of the source dotfiles. The original targets were all absolute
  paths to the identical checkout content. Inspect active HM ownership before
  replacing a deployed link with any recovery link.
- Nix rollback restores Nix generations, not mutable dotfile contents, Brew/npm
  installations, or installer changes. See README for recovery details.

Do not rely on an environment-only check flag when executing a generated activation
script. Build/evaluate without activation first and inspect the generated checks
and ownership; ordinary switching already performs its built-in system checks.
No check-only invocation of that generated script is included in repo tooling.

## Lock file provenance

Stable inputs: nixpkgs `nixpkgs-26.05-darwin`, nix-darwin `nix-darwin-26.05`, HM
`release-26.05`; both modules follow the same nixpkgs node. Revisions are pinned.
Before Nix installation, GitHub source NAR hashes were independently calculated,
using a serializer verified against an upstream Nix-generated nixpkgs lock hash.
After installation Nix successfully consumed those pins without rewriting the lock.
The lock is staged, not committed, per the user's instruction.

## Remaining manual verification

AeroSpace history/monitor/mouse behavior; Ghostty visual settings/shell integration;
Neovim lazy plugin restore/native parser health and LSP attachment; Typst browser
and PDF preview; Xournal++ toolbar; Karabiner rule availability; app permissions.
Those GUI/workflow checks were not claimed as passed. SketchyBar's starter needs
visual testing on the actual displays; it remains opt-in and the native menu bar
is unchanged. Review the AeroSpace/SketchyBar separate-Spaces conflict before
starting it. No default-shell change or permission grant was performed.
