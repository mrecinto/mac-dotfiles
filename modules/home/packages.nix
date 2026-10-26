{ pkgs, ... }:
{
  # Incremental adoption: existing CLI tools stay in Homebrew on this Mac.
  # This LSP is enabled by nvim but missing from the audited PATH.
  home.packages = [ pkgs.lua-language-server pkgs.matugen ];
  # Future Linux hosts should add their own package set and Yazi opener overrides.
}
