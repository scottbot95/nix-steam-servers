{
  description = "Nix Flake for managing various steam servers";

  nixConfig = {
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    steam-fetcher = {
      url = "github:aidalgol/nix-steam-fetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flake-parts
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-root.url = "github:srid/flake-root";

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

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib.extend (final: _: import ./lib.nix final);
  in
    flake-parts.lib.mkFlake {
      inherit inputs;
      specialArgs = {inherit lib;};
    } {
      imports = [
        inputs.devshell.flakeModule
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
        ./flake-shell.nix
        ./formatter.nix
        ./mkdocs.nix
        ./modules
        ./pkgs
      ];
      systems = ["x86_64-linux"];
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
