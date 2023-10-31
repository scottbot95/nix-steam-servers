args@{ inputs, ... }:
let
  modules = {
    "7-days-to-die" = import ./7-days-to-die args;
  };
in {
  imports = [
    ./testing.nix
  ];

  flake.nixosModules = modules // {
    default = {
      imports = builtins.attrValues modules;
    };
  };
}