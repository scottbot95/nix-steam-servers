{
  description = "Nix Flake for managing various steam servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

    steam-fetcher = {
      url = "github:aidalgol/nix-steam-fetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    flake-parts,
    nixpkgs,
    ...
  }: let
    lib = nixpkgs.lib.extend (final: _: import ./lib.nix final);
  in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
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
