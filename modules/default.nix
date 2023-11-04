args@{ inputs, ... }:
let
  modules = {
    "7-days-to-die" = import ./7-days-to-die args;
  };
in {
  imports = [
    ./testing.nix
  ];

  flake.nixosModules.default = {config, lib, ...}: 
    with lib;
    let
      cfg = config.services.steam-servers;
      anyServersEnabled = any 
        (game: any
          (serverConf: serverConf.enable)
          (builtins.attrValues cfg.${game}))
        (builtins.attrNames modules);
    in {
      imports = builtins.attrValues modules;

      options.services.steam-servers = {
        datadir = mkOption {
          type = types.path;
          default = "/var/lib/steam-servers";
          description = mdDoc ''
            Base directory for all steam servers created with this module.
          '';
          example = "/mnt/nfs/steam";
        };

        user = mkOption {
          type = types.str;
          default = "steam-server";
          description = mdDoc ''
            User to use when running steam servers and creating top-level resources
          '';
        };

        group = mkOption {
          type = types.str;
          default = "steam-server";
          defaultText = literalExpression "\${cfg.user}";
          description = mdDoc "Group to use when running steam servers";
        };
      };

      config = mkIf anyServersEnabled {
        systemd.tmpfiles.rules = [
          "d ${cfg.datadir} 775 steam-server steam-server"
        ];

        users.users.${cfg.user} = {
          isSystemUser = true;
          home = "${cfg.datadir}";
          group = "${cfg.group}";
        };

        users.groups.${cfg.group} = {};
      };
    };
}