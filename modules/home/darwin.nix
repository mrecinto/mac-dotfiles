{ config, lib, ... }:
let
  live = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.directory}/.config/${name}";
  };
in {
  # Yazi and Neovim currently contain macOS commands; see docs/audit.md for Linux work.
  # Link only the rule asset, preserving active karabiner.json and real parent dirs.
  xdg.configFile = lib.genAttrs (builtins.fromJSON (builtins.readFile ./links.json)).darwin live;
}
