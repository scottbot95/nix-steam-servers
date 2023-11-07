{
  description = "Nix Flake for managing various steam servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    steam-fetcher = {
      url = "github:aidalgol/nix-steam-fetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # utils
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devour-flake = {
      url = "github:srid/devour-flake";
      flake = false;
    };
  };

  outputs = inputs@{
    flake-parts,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib.extend (final: _: import ./lib.nix final);
  in
    flake-parts.lib.mkFlake {
      inherit inputs;
      specialArgs = { inherit lib; };
    } {
      imports = [
        inputs.devshell.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay 
        # inputs.treefmt-nix.flakeModule
        ./flake-shell.nix
        ./mkdocs.nix
        ./modules
        ./pkgs
      ];
      systems = [ "x86_64-linux" ];
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
