{
  config,
  lib,
  ...
}:
with lib; let
  moduleLib = import ../lib.nix lib;
  inherit (moduleLib) mkOpt configType;

  baseCfg = config.services.steam-servers;

  serverOptions = {name, ...}: {
    options = {
      enable = mkEnableOption (mdDoc "this game server");

      datadir = mkOption {
        type = types.path;
        default = "${baseCfg.datadir}/${name}";
        defaultText = literalExpression "\${services.steam-servers.datadir}/\${name}";
        description = mdDoc ''
          Directory to store save state of the game server. (eg world, saves, etc)
        '';
      };

      executable = mkOption {
        type = types.str;
        example = "./7DaysToDieServer.x86_64";
        description = mdDoc ''
          Executable for the starting the server.

          May be an absolute path or one relative to `datadir`
        '';
      };

      args = mkOption {
        type = with types; listOf str;
        default = [];
        description = mdDoc ''
          Arguments passed to [executable](#servicessteam-serversserversnameexecutable)
        '';
      };

      autostart = mkOpt types.bool true ''
        Whether to start this server automatically.

        When `false`, services can be started manually via `systemctl start`.
      '';

      description = mkOption {
        type = types.str;
        default = "";
        description = mdDoc ''
          Description of this steam server.
          Will be used for the systemd unit.
        '';
      };

      symlinks = mkOption {
        type = with types; attrsOf (either path configType);
        default = {};
        description = mdDoc ''
          Set of files to symlink into [datadir](#servicessteam-serversserversnamedatadir).
          The `name` is the path relative to [datadir](#servicessteam-serversserversnamedatadir).

          All symlinks will be cleaned-up when the service stops
        '';
      };
      dirs = mkOption {
        type = with types; attrsOf path;
        default = {};
        description = mdDoc ''
          Set of directories to copy into [datadir](#servicessteam-serversserversnamedatadir).
          The `name` is the path relative to [datadir](#servicessteam-serversserversnamedatadir)
          and the `value` is the path to the directory to be copied into the approriate location.

          If files in the source are newer than their copy in `datadir`, they will be overwritten.
        '';
      };
      files = mkOption {
        type = with types; attrsOf (either path configType);
        default = {};
        description = mdDoc ''
          Set of files to copy into [datadir](#servicessteam-serversserversnamedatadir).
          The `name` is the path relative to [datadir](#servicessteam-serversserversnamedatadir)
          and the `value` is the path to the file to be copied into the approriate location.

          This can be useful for files that the game server expects to be able to open
          in write mode.

          Files copied this way will be removed after service shutdown.
        '';
      };
    };
  };
in {
  options.services.steam-servers.servers = mkOption {
    type = with types; attrsOf (submodule serverOptions);
    default = {};
    description = mdDoc ''
      Options for configuring a generic game server.
    '';
  };
}
