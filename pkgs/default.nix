{inputs, ...}: let
  mkPackages = pkgs: {
    "7-days-to-die" = pkgs.callPackage ./7-days-to-die {};
  };
in {
  perSystem = {pkgs, ...}: {
    packages = mkPackages (pkgs.extend inputs.steam-fetcher.overlays.default);
  };

  # Don't use easyOverlay/packages from perSystem to propogate allowUnfree settings
  flake.overlays.default = final: _: (mkPackages final);
}
