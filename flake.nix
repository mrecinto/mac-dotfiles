{
  description = "Matthew's live-editable macOS dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      host = import ./hosts/macbook/settings.nix;
      darwin = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit host; };
        modules = [
          ./hosts/macbook
          home-manager.darwinModules.home-manager
        ];
      };
    in {
      darwinConfigurations.macbook = darwin;
      # Reusable on a future Linux HM/NixOS host; no macOS modules imported here.
      homeModules.default = import ./modules/home;
      packages.${host.system}.default = darwin.system;
      apps.${host.system}.darwin-rebuild = {
        type = "app";
        meta.description = "Pinned nix-darwin rebuild command";
        program = "${nix-darwin.packages.${host.system}.darwin-rebuild}/bin/darwin-rebuild";
      };
      checks.${host.system} = {
        darwin = darwin.system;
        home = darwin.config.home-manager.users.${host.username}.home.activationPackage;
      };
    };
}
