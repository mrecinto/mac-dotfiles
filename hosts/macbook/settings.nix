# Edit for another Mac BEFORE building. Do not put secrets here.
rec {
  username = "matthew";
  homeDirectory = "/Users/${username}";
  # Absolute runtime checkout path; NOT a Nix path literal or self.outPath.
  dotfilesDirectory = "${homeDirectory}/dotfiles";
  system = "aarch64-darwin";
}
