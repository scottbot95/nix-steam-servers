{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  baseCfg = config.services.steam-servers;
  moduleLib = import ../lib.nix lib;
  inherit (moduleLib) mkOpt;

  serverModule = {name, ...}: {
    options = {
      enable = mkEnableOption (mdDoc "Palworld Dedicated Server");

      package = mkOption {
        type = types.package;
        default = pkgs.palworld;
        defaultText = literalExpression "pkgs.palworld";
        description = mdDoc "Package to use for Palworld binary";
      };

      datadir = mkOption {
        type = types.path;
        default = "${baseCfg.datadir}/palworld-${name}";
        defaultText = literalExpression "\${services.steam-servers.datadir}/palworld/\${name}";
        description = mdDoc ''
          Directory to store save state of the game server. (eg world, saves, etc)
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to open ports in the firewall.";
      };

      port = mkOption {
        type = types.port;
        default = 8211;
        description = mdDoc "UDP port to listen on";
      };

      worldSettings = mkOption {
        # inherit (settingsFormat) type;
        type = types.attrs;
        default = {};
        description = mdDoc "World settings used to generate PalWorldSettings.ini";
      };

      extraArgs = mkOpt (with types; listOf str) [] "Extra command line arguments to pass to the server";
    };
  };
in {
  options.services.steam-servers.palworld = mkOption {
    type = types.attrsOf (types.submodule serverModule);
    default = {};
    description = mdDoc ''
      Options to configure one or more Stationers servers.
    '';
  };
}
