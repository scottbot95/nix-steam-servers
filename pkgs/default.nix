{inputs, ...}: let
  overlay = pkgs: _: {
    "7-days-to-die" = pkgs.callPackage ./7-days-to-die {};
  };
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
    };
  };

  # Don't use easyOverlay/packages from perSystem to propogate allowUnfree settings
  flake.overlays.default = overlay;
}
