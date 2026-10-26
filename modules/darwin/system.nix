{ ... }:
{
  # Use upstream multi-user Nix, managed by nix-darwin after first activation.
  nix.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.optimise.automatic = false;
  nix.gc.automatic = false;
  system.stateVersion = 7;
  # Deliberately no defaults, default-shell changes, or third-party services.
}
