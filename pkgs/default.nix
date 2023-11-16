{
  inputs,
  lib,
  ...
}: let
  pkgsToImport = {
    "7-days-to-die" = ./7-days-to-die;
    stationeers = ./stationeers;
  };

  overlay = pkgs: _:
    lib.mapAttrs
    (_: file: pkgs.callPackage file {})
    pkgsToImport;
in {
  perSystem = {
    config,
    system,
    ...
  }: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.steam-fetcher.overlays.default
        overlay
      ];
      config.allowUnfree = true;
    };
  in {
    packages = {
      "7-days-to-die" = pkgs."7-days-to-die";
      inherit
        (pkgs)
        stationeers
        ;
    };
  };

  # Don't use easyOverlay/packages from perSystem to propogate allowUnfree settings
  flake.overlays.default = overlay;
}
