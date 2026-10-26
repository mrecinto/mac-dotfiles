{ ... }:
{
  imports = [ ./dotfiles.nix ./packages.nix ];
  home.stateVersion = "26.05";
  xdg.enable = true;
  # Shell, prompt, editor and plugin config remain owned by the live files.
  # Do not enable HM programs.fish/neovim/starship over these same paths.
}
