{
  self,
  inputs,
  lib,
  ...
}: let
  eachModule = with lib;
    filterAttrs
    (name: file: (name != "default") && (hasSuffix "default.nix" file))
    (flattenTree {tree = rakeLeaves ./.;});

  modules = with lib;
    mapAttrs'
    (name:
      nameValuePair
      (removeSuffix ".default" name))
    eachModule;
in {
  imports = [
    ./testing.nix
  ];

  flake.nixosModules.default = {
    config,
    pkgs,
    lib,
    ...
  }:
    with lib; let
      cfg = config.services.steam-servers;
      userHome = config.users.users.${cfg.user}.home;
      anyServersEnabled =
        any
        (conf: conf.enable)
        (builtins.attrValues cfg.servers);
    in {
      imports =
        [
          ./options.nix
        ]
        ++ (builtins.attrValues modules);

      config = mkIf anyServersEnabled {
        nixpkgs.overlays = [
          self.overlays.default
          inputs.steam-fetcher.overlays.default
        ];

        users.users."${cfg.user}" = {
          isSystemUser = true;
          home = "${cfg.datadir}";
          createHome = true;
          homeMode = "750";
          inherit (cfg) group;
        };

        users.groups."${cfg.group}" = {};

        systemd.tmpfiles.rules = [
          "d ${userHome}/.steam 0755 ${cfg.user} ${cfg.user} - -"
          "L+ ${userHome}/.steam/sdk64 - - - - ${pkgs.steamworks-sdk-redist}/lib"
        ];
      };
    };
}
