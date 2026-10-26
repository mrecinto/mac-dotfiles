#!/bin/bash
# No installation, activation, symlink changes, or package cleanup.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m unittest discover -s tests -v
if command -v fish >/dev/null; then
  fish -n .config/fish/config.fish .config/fish/conf.d/00-nix-path.fish
fi
for script in .config/aerospace/scripts/*.sh .config/nvim/scripts/*.sh .config/yazi/scripts/fix-xopp; do
  bash -n "$script"
done
sh -n .config/sketchybar/sketchybarrc
# Support a just-installed Nix before the caller has restarted their shell.
if ! command -v nix >/dev/null && [ -x /nix/var/nix/profiles/default/bin/nix ]; then
  export PATH="/nix/var/nix/profiles/default/bin:$PATH"
fi
if ! command -v nix >/dev/null; then
  echo 'PENDING: Nix syntax/module evaluation, flake checks and builds require an approved Nix installation.' >&2
  exit 2
fi
while IFS= read -r file; do
  nix-instantiate --parse "$file" >/dev/null
done < <(find hosts modules -name '*.nix' -type f; printf '%s\n' flake.nix)
nix --extra-experimental-features 'nix-command flakes' flake metadata --no-write-lock-file >/dev/null
nix --extra-experimental-features 'nix-command flakes' flake check --no-build --no-write-lock-file
host_system=$(nix --extra-experimental-features 'nix-command flakes' eval --raw .#darwinConfigurations.macbook.config.nixpkgs.hostPlatform.system)
nix --extra-experimental-features 'nix-command flakes' build --no-link --no-write-lock-file ".#checks.$host_system.home" .#darwinConfigurations.macbook.system
