{ inputs, ... }:
let
  mkPackages = pkgs: {
    "7-days-to-die" = pkgs.callPackage ./7-days-to-die {};
  };
in
{
  perSystem = { config, self', inputs', system, ... }:
    let 
      pkgs = import inputs.nixpkgs { 
        inherit system;
        overlays = [
          inputs.steam-fetcher.overlays.default
        ];
      };
    in {
      packages = mkPackages pkgs;

    };

  flake.overlays.default = final: prev: (mkPackages final);
}