{
  inputs,
  lib,
  ...
}: let
  pkgsToImport = {
    "7-days-to-die" = ./7-days-to-die;
    palworld = ./palworld;
    stationeers = ./stationeers;
  };

  overlay = pkgs: _:
    lib.mapAttrs
    (_: file: pkgs.callPackage file {})
    (pkgsToImport // {mkSteamPackage = ./mkSteamPackage.nix;});
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
    packages =
      lib.filterAttrs
      (k: _: builtins.hasAttr k pkgsToImport)
      pkgs;
  };

  # Don't use easyOverlay/packages from perSystem to propogate allowUnfree settings
  flake.overlays.default = overlay;
}
