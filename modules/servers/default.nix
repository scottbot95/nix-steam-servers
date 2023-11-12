_: {
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  moduleLib = import ../lib.nix lib;
  inherit (moduleLib) mkSymlinks mkDirs mkFiles normalizeFiles;

  baseCfg = config.services.steam-servers;
  cfg = baseCfg.servers;
in {
  imports = [
    ./options.nix
  ];

  config = {
    systemd.services =
      mapAttrs
      (name: conf: let
        symlinks = normalizeFiles conf.symlinks;
        inherit (conf) dirs;
        files = normalizeFiles conf.files;
      in {
        inherit (conf) description;
        wantedBy = mkIf conf.autostart ["multi-user.target"];
        after = ["network.target"];

        script = ''
          cd ${conf.datadir}
          ${conf.executable} ${concatStringsSep " \\\n" conf.args}
        '';

        preStart = ''
          mkdir -p ${conf.datadir}

          cd ${conf.datadir}

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
          cd ${conf.datadir}

          ${rmSymlinks}
          ${rmFiles}
        '';

        serviceConfig = {
          Restart = mkDefault "on-failure";
          User = mkDefault "${baseCfg.user}";
          Group = mkDefault "${baseCfg.group}";

          ProtectClock = mkDefault true;
          ProtectProc = mkDefault "noaccess";
          ProtectKernelLogs = mkDefault true;
          ProtectKernelModules = mkDefault true;
          ProtectKernelTunables = mkDefault true;
          ProtectControlGroups = mkDefault true;
          ProtectHostname = mkDefault true;
          PrivateDevices = mkDefault true;
          RestrictRealtime = mkDefault true;
          RestrictNamespaces = mkDefault true;
          LockPersonality = mkDefault true;
          MemoryDenyWriteExecute = mkDefault true;
          SystemCallFilter = mkDefault ["@system-service" "~@privileged"];
        };
      })
      cfg;
  };
}
