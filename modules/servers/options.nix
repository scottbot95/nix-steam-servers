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

      useTmux = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether or not to run server inside a tmux session.
          This can be useful for servers that have a console you can run commands in.

          If enabled, a tmux socket will be created at `$RUNTIME_DIRECTORY/steam-servers/''${name}`
          and the server executable will be ran inside the tmux session.

          WARNING: At this time terminal output from tmux is not sent to journald.
          This means that you will NOT have persistant logs without some other mechanism.
          This can make debuging server crashes VERY difficult, but is necessary for some servers
        '';
      };
      tmuxStopKeys = mkOption {
        type = types.str;
        default = "^C";
        description = mdDoc ''
          When using tmux, what keys to send via `tmux send-keys` to
          shutdown the server.
        '';
        example = "/stop Enter";
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
