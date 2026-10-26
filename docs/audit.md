# Migration audit — 2026-10-26

This records the environment before migration; subsequent results are in
[validation and activation](validation.md). The original files under `.config/`
are the source of truth. No existing application
configuration was rewritten. Inventory: [installed packages](inventory.md).

## Host and Git

- Apple Silicon (`arm64` / Nix `aarch64-darwin`), macOS 27.0 build 26A428.
- User `matthew`, home `/Users/matthew`, checkout `/Users/matthew/dotfiles`.
- Existing branch `main`; migration branch `migration/nix-darwin`. Remote remains
  `git@github.com:mrecinto/mac-dotfiles.git`. History and branches retained.
- Pre-existing edits: `.config/fish/config.fish` and `.config/xournalpp/settings.xml`.
  Untracked `.config/fish/fish_variables` contained PICO_HOME and a user npm PATH;
  left intact and now ignored as local state. It is not included in the flake.
- `.config/.DS_Store` was already tracked; left untouched, new instances ignored.
- Nix absent. Homebrew, Node/npm, Fish and Apple Command Line Tools present.
- `$SHELL` reports `/opt/homebrew/bin/fish`. Directory Services queries failed in
  this execution environment; the account login-shell record could not be verified.
  No default-shell change is configured.

## Complete existing repository inventory

- `aerospace/`: active `aerospace.toml`, alternative `aerospace_1.toml`, `note.md`,
  executable `scripts/workspace.sh` and `workspace_1.sh`.
- `fish/`: `config.fish` and local universal state `fish_variables`.
- `ghostty/config`; empty `starship.toml` (Starship uses its defaults).
- `karabiner/assets/complex_modifications/aerospace.json`.
- `nvim/`: `init.lua`, `lazy-lock.json`; Lua plugins for autopairs, blink completion,
  bufferline, img-clip, LSP, LuaSnip, Neo-tree, smear-cursor, Telescope, Tree-sitter,
  Typst; executable `scripts/typst-preview.sh`, `scripts/typst-zathura.sh`.
- `tmux/tmux.conf`; `zathura/zathurarc`.
- `xournalpp/`: `settings.xml`, alternative `settings_1.xml`, `toolbar.ini`.
- `yazi/`: `keymap.toml`, `yazi.toml`, executable `scripts/fix-xopp`,
  `templates/default.xopp`, `templates/test.xopp`, empty `test.xopp`.
- `.config/.DS_Store`. There was no SketchyBar configuration or README/Nix setup.

All paths above are beneath `.config/`. No repository-internal symlinks found.
The `.xopp` templates are gzip-compressed documents, preserved byte-for-byte.
Alternative configs are retained; they are not asserted to be active.

## Existing link ownership

These ten existing absolute symlinks point to the identically named paths beneath
`/Users/matthew/dotfiles/.config/`:

- `~/.config/{aerospace,fish,ghostty,nvim,tmux,xournalpp,yazi,zathura}`
- `~/.config/starship.toml`
- `~/.config/karabiner/assets/complex_modifications/aerospace.json`

`~/.config` and `~/.config/karabiner` are real directories. The latter contains
active `karabiner.json` and automatic backups outside this repository. Only the
existing rule asset will be managed. Other real directories (`gtk-3.0`, `uv`,
`linearmouse`) remain unmanaged. `~/.gitconfig` is a real file containing public
Git name/email; left unmanaged. No `~/.aerospace.toml` was found.

HM directory links replace these direct links with generation-owned links that
ultimately resolve to the same checkout. Existing links are NOT silently forced.
The initial preflight reported ten handoffs and a new SketchyBar target.
The explicit handoff helper can move matching absolute symlinks into a timestamped
backup before activation. In this migration HM adopted identical links directly
before that backup step; see validation.md for the incident and recovery records.
A real file/directory or unrelated/broken/relative link is refused for manual review.

## Configuration dependencies and behavior preserved

| Config | Dependencies / existing behavior |
| --- | --- |
| AeroSpace | Brew cask/CLI, Bash, `osascript`, Ghostty, Zen. Numbered 1–10 and special W/A/S/D/I/O workspaces, per-monitor history under `/tmp/aerospace-workspace-state-$USER`, focus/mouse keybindings and summon behavior retained. Active script has a blank line before its shebang; preserved, syntax checked. |
| Ghostty | Font size 14; no explicit font-family; Catppuccin light/dark themes, 10-pixel padding, tmux digit bindings. No explicit shell override; default shell and Ghostty's integration remain authoritative. |
| Neovim | lazy.nvim plus lazy-lock.json; Git/network for first plugin restore; `cc`, make, tree-sitter CLI for parsers/native builds; `rg`, `fd` for search; `pngpaste` for image clipboard; clangd, Tinymist, Lua language server for configured LSPs. |
| Typst | Brew typst/tinymist; typstyle formatting provided through Tinymist; Zen for preview, `open`, `osascript`/System Events for older preview script; zathura + PDF Poppler plugin for PDF watcher. |
| Yazi | EDITOR=nvim; Finder/Preview/`open`, Xournal++; custom empty `.xopp` repair copies `templates/default.xopp`; scripts and templates remain executable/editable. Optional preview/search tools: ffmpeg, sevenzip, Poppler, ImageMagick, fd, rg, fzf, jq. No custom Yazi plugins or theme found. |
| Fish | Existing functions, EDITOR/VISUAL, Starship init, Yazi cwd wrapper, `.local/bin` PATH; PICO_HOME and personal course/document paths preserved. Existing `cfg` assumes `~/dotfiles`. |
| tmux | Brew tmux, Ghostty bindings, native mouse, navigation and reload bindings preserved. |
| Xournal++ | Installed app + custom toolbar/settings; absolute palette/TeX and last-save paths preserved; `/Library/TeX/texbin/pdflatex` missing. LaTeX insertion needs a separate TeX installation if used. |
| Zathura | Custom Brew tap, PDF Poppler plugin, GTK dependencies; existing theme and keymaps retained. |
| Git | Brew git plus existing unmanaged global identity and credentials. No signing/credential settings invented. |

Every required CLI checked resolves on this Mac except `lua-language-server` and
new `sketchybar`. clangd is `/usr/bin/clangd`; most others are `/opt/homebrew/bin`.
The Nix module adds only the missing Lua language server. Its pinned nixpkgs
metadata supports Darwin; substitution/build and executable version checks subsequently passed; see validation.md.

## Shell, PATH, npm and other installations

- zsh login config runs `/opt/homebrew/bin/brew shellenv zsh`; `.zshrc` prepends
  `~/.npm-global/bin`. `.profile` has Android/PICO SDK paths and `~/trace_processor`.
  These files remain unmanaged; Fish does not automatically source `.profile`.
- Audited Fish PATH begins `.local/bin`, `.npm-global/bin`, Codex's injected path,
  then Homebrew bin/sbin and system directories. There are duplicated inherited
  entries and Ghostty/Codex process-specific entries; these are not persisted.
- The added guarded Fish conf.d file appends available Nix profiles, preserving
  existing Brew/npm precedence, and restores the existing npm prefix on new Macs.
  It does not regenerate config.fish, initialize Starship twice, or write universal
  variables. It also keeps Homebrew ahead of Apple Git after the Nix installer
  changes startup PATH ordering. Existing initialization remains the sole prompt initialization.
- Global npm prefix is `/Users/matthew/.npm-global`; installed packages and exact
  observed versions are recorded in inventory.md. No npm installs/updates executed.
- `.local/bin` includes uv/uvx, Claude, and uv-managed graphify/gv. SDKs, local tools,
  documents, app sign-ins and licenses need manual restoration; they are not dotfiles.
- Zen and Xournal++ are app bundles outside Homebrew; automatic Brew adoption is
  intentionally avoided. The Homebrew Xournal++ cask is currently disabled; restore
  it using its upstream installer. Existing Homebrew casks/taps and requested formulae are
  declared. Transitive dependencies are inventoried rather than all made explicit.

Nix-managed dependencies are pinned; Homebrew/npm/plugin runtime downloads are
separate reproducibility boundaries. `--no-upgrade`, disabled Brew auto-update,
`HOMEBREW_NO_INSTALL_CLEANUP`, and cleanup="none" reduce initial disruption.
Installing missing formulae may still change shared dependencies. Inspect Brew's
plan/output before accepting the first activation. Never automatically uninstall
Brew duplicates when moving a tool into Nix. Check `type -a TOOL` in a real terminal
and Fish session: zsh and Fish startup ordering can differ after nix-darwin writes
its system shell integration.

## Permissions and manual settings

- AeroSpace: Accessibility; AppleScript control of Ghostty may prompt for Automation.
- Karabiner: Input Monitoring, Accessibility/driver permissions as prompted. Import
  or enable the existing rule through its UI; do not replace karabiner.json.
- Older Typst preview script: Automation to Zen/System Events and Accessibility for
  UI keystrokes. Document access prompts may apply to Terminal/Ghostty/Neovim.
- Wacom/Logitech and other installed device tools need their own installers and
  permissions. No security settings are managed by this flake.
- AeroSpace's note asks for “Displays have separate Spaces” OFF. SketchyBar's
  [upstream setup](https://felixkratz.github.io/SketchyBar/setup) says ON is required.
  This is a real conflict to review manually, not an existing setting we verified.
  Starter bar has no space subscriptions; service remains stopped. Native menu bar
  visibility is untouched. Its simple label needs no additional font/plugin.
- macOS 27 compatibility of Nix, Homebrew bottles, AeroSpace and SketchyBar has not
  been fully runtime-tested. Builds and activation subsequently passed, and AeroSpace
  responded on its focused workspace and monitor; remaining GUI behavior needs
  manual verification.

## Future Linux

The flake exports `homeModules.default` with portable package/link declarations;
no Darwin applications are imported by that module. A future Linux HM/NixOS host
must set username/home/dotfiles path and install the editor, shell, Git, prompt, etc.
Neovim's theme probe uses `defaults`, and its Typst preview uses `open`/Zen. Override
those before using the shared editor config on Linux. Yazi is deliberately linked
only by the Darwin module until its macOS openers have Linux alternatives. Ghostty,
AeroSpace, SketchyBar, Karabiner and Xournal++'s Mac-specific config remain separate.
No speculative NixOS machine configuration has been added.
