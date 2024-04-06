{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  moduleLib = import ../lib.nix lib;
  inherit (moduleLib) mkSymlinks mkDirs mkFiles normalizeFiles;

  cfg = config.services.steam-servers;
  inherit (cfg) servers;
in {
  imports = [
    ./options.nix
  ];

  config = {
    systemd.tmpfiles.rules =
      mapAttrsToList
      (
        _name: conf: "d ${conf.datadir} 0750 ${cfg.user} ${cfg.group} - -"
      )
      servers;

    environment.systemPackages =
      mkIf
      (builtins.any
        (conf: conf.useTmux)
        (builtins.attrValues servers))
      [pkgs.tmux];

    systemd.services =
      mapAttrs
      (name: conf: let
        symlinks = normalizeFiles conf.symlinks;
        inherit (conf) dirs;
        files = normalizeFiles conf.files;
        startServer = "${conf.executable} ${concatStringsSep " " conf.args}";
      in
        mkMerge [
          (mkIf conf.useTmux {
            serviceConfig = let
              tmux = "${getExe pkgs.tmux}";
              tmuxSock = "$RUNTIME_DIRECTORY/${name}.sock";
            in {
              RuntimeDirectory = mkDefault "steam-servers";
              RuntimeDirectoryPreserve = mkDefault true;

              # These don't use mkDefault as they are required when launching detached tmux
              Type = "forking";
              GuessMainPID = true;

              ExecStart = pkgs.writeShellScript "${name}-start-tmux" ''
                ${tmux} -S ${tmuxSock} new -d ${startServer}
              '';

              ExecStop = pkgs.writeShellScript "${name}-stop-tmux" ''
                if ! [ -d "/proc/$MAINPID" ]; then
                  exit 0
                fi

                ${tmux} -S ${tmuxSock} send-keys ${conf.tmuxStopKeys}
              '';
            };
          })
          (mkIf (!conf.useTmux) {
            script = ''
              ${startServer}
            '';
          })
          {
            inherit (conf) description;
            wantedBy = mkIf conf.autostart ["multi-user.target"];
            after = ["network.target"];

            preStart = ''
              ${mkSymlinks pkgs name symlinks}
              ${mkDirs pkgs name dirs}
              ${mkFiles pkgs name files}
            '';

            postStop = let
              rmSymlinks =
                pkgs.writeShellScript "${name}-rm-symlinks"
                (
                  concatStringsSep "\n"
                  (mapAttrsToList (n: _v: "unlink \"${n}\"") symlinks)
                );
              rmFiles =
                pkgs.writeShellScript "${name}-rm-symlinks"
                (
                  concatStringsSep "\n"
                  (mapAttrsToList (n: _v: "rm \"${n}\"") symlinks)
                );
            in ''
              ${rmSymlinks}
              ${rmFiles}
            '';

            serviceConfig = {
              Restart = mkDefault "on-failure";
              User = mkDefault "${cfg.user}";
              Group = mkDefault "${cfg.group}";
              WorkingDirectory = mkDefault "${conf.datadir}";

              PrivateDevices = mkDefault true;
              PrivateTmp = mkDefault true;
              PrivateUsers = mkDefault true;
              ProtectClock = mkDefault true;
              ProtectProc = mkDefault "noaccess";
              ProtectKernelLogs = mkDefault true;
              ProtectKernelModules = mkDefault true;
              ProtectKernelTunables = mkDefault true;
              ProtectControlGroups = mkDefault true;
              ProtectHostname = mkDefault true;
              RestrictRealtime = mkDefault true;
              RestrictNamespaces = mkDefault true;
              LockPersonality = mkDefault true;
              MemoryDenyWriteExecute = mkDefault true;
              SystemCallFilter = mkDefault ["@system-service" "~@privileged"];
            };
          }
        ])
      servers;
  };
}
