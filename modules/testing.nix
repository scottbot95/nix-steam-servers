{
  self,
  inputs,
  lib,
  ...
}: let
  eachTest = with lib;
    filterAttrs
    (_name: hasSuffix ".test.nix")
    (flattenTree {
      tree = rakeLeaves ./.;
      separator = "-";
    });
in {
  perSystem = {
    system,
    lib,
    ...
  }: let
    # create a custom nixpkgs with our flake packages available
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [
        self.overlays.default
        inputs.steam-fetcher.overlays.default
      ];
      config.allowUnfree = true;
    };
    checks = with lib;
      mapAttrs'
      (name: test:
        nameValuePair "testing-${removeSuffix ".test" name}"
        (inputs.nixpkgs.lib.nixos.runTest {
          hostPkgs = pkgs;

          # speed up evaluation by skipping docs
          defaults.documentation.enable = lib.mkDefault false;

          # make self available in test modules and our custom pkgs
          node.specialArgs = {inherit self pkgs;};

          # import all of our flake nixos modules by default
          defaults.imports = [
            self.nixosModules.default
          ];

          # import the test module
          imports = [test];
        })
        .config
        .result)
      eachTest;
  in {
    inherit checks;
  };
}
