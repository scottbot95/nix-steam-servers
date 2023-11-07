{ self, inputs, ... }:
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
        config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [
          "7-days-to-die-server"
          "steamworks-sdk-redist"
        ];
      };
    in {
      packages = mkPackages pkgs;

      overlayAttrs = self'.packages;
    };
}