{ config, lib, ... }:
let
  cfg = config.dotfiles;
  live = name: {
    source = config.lib.file.mkOutOfStoreSymlink "${cfg.directory}/.config/${name}";
  };
in {
  options.dotfiles.directory = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/dotfiles";
    description = "Absolute path to the mutable Git checkout (outside ~/.config).";
  };
  config = {
    assertions = [ {
      assertion = lib.hasPrefix "/" cfg.directory
        && !(lib.hasPrefix "${config.home.homeDirectory}/.config" cfg.directory)
        && !(lib.hasPrefix "/nix/store/" cfg.directory);
      message = "dotfiles.directory must be an absolute checkout path outside ~/.config and /nix/store.";
    } ];
    xdg.configFile = lib.genAttrs (builtins.fromJSON (builtins.readFile ./links.json)).shared live;
  };
}
