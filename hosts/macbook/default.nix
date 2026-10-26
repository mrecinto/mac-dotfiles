{ host, ... }:
{
  imports = [ ../../modules/darwin ];
  nixpkgs.hostPlatform = host.system;
  system.primaryUser = host.username;
  users.users.${host.username}.home = host.homeDirectory;
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # No force or automatic backup: collisions must be reviewed before activation.
    users.${host.username} = {
      imports = [ ../../modules/home ../../modules/home/darwin.nix ];
      home.username = host.username;
      home.homeDirectory = host.homeDirectory;
      dotfiles.directory = host.dotfilesDirectory;
    };
  };
}
