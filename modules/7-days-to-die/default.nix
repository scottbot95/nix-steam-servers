{ self, inputs, ... }:
{ config, pkgs, lib, ... }:
with lib;
let
  modulesLib = import ../lib.nix lib;
  inherit (modulesLib) writeXML;
  mkSymlinks = modulesLib.mkSymlinks pkgs;
  mkDirs = modulesLib.mkDirs pkgs;

  baseCfg = config.services.steam-servers;
  cfg = config.services.steam-servers."7-days-to-die";
in
{
  imports = [
    (import ./options.nix { inherit self; })
  ];

  config =
    let
      enabledServers = filterAttrs (_: conf: conf.enable) cfg;
    in
    mkIf (enabledServers != {}) {
      networking.firewall = {
        allowedUDPPorts = flatten (map 
          (conf:
            let
              basePort = conf.config.ServerPort;
            in
              (optionals conf.openFirewall [basePort (basePort + 2)]))
          (builtins.attrValues enabledServers));
      };

      systemd.services = mapAttrs'
        (name: conf:
          let
            configFile = writeXML "serverconfig.xml" conf.config;
            args = [
              "-logfile"
              (if conf.logFile != null then conf.logFile else "${conf.datadir}/output_log__$(date +%Y-%m-%d__%H-%M-%S).txt")
              "-quit"
              "-batchmode"
              "-nographics" 
              "-dedicated" 
              "-configfile=${configFile}"
            ] ++ conf.extraArgs;
            symlinks = {
              "${baseCfg.datadir}/.steam/sdk64/steamclient.so" = "${conf.package}/steamclient.so";

              "7DaysToDieServer.x86_64" = "${conf.package}/7DaysToDieServer.x86_64";
              "7DaysToDieServer_Data"   = "${conf.package}/7DaysToDieServer_Data";
              "Data"                    = "${conf.package}/Data";
              "platform.cfg"            = "${conf.package}/platform.cfg"; # TODO not sure if this one is needed
              "UnityPlayer.so"          = "${conf.package}/UnityPlayer.so";
              "libstdc++.so.6"          = "${conf.package}/libstdc++.so.6";
              "steamclient.so"          = "${conf.package}/steamclient.so";
              "Mods"                    = "${conf.package}/Mods";
            };
          in
          {
            name = "7-days-to-die-${name}";
            value = rec {
              description = "7 Days to Die Server ${name}";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];

              # enable = false;

              script = ''
                cd ${conf.datadir}
                ${conf.datadir}/7DaysToDieServer.x86_64 ${concatStringsSep " \\\n" args}
              '';

              preStart = ''
                umask u=rwx,g=rx,o=rx
                mkdir -p ${conf.datadir}
                mkdir -p ${baseCfg.datadir}/.steam/sdk64

                cd ${conf.datadir}

                ${mkSymlinks "7-days-to-die-${name}" symlinks}
              '';

              postStop =
                let
                  rmSymlinks = pkgs.writeShellScript "7-days-to-die-${name}-rm-symlinks"
                    (concatStringsSep "\n"
                      (mapAttrsToList (n: v: "unlink \"${n}\"") symlinks)
                    );
                in
                ''
                  cd ${conf.datadir}

                  ${rmSymlinks}
                '';

              serviceConfig = {
                Restart = "on-failure";
                User = "${baseCfg.user}";
                Group = "${baseCfg.group}";

                ProtectClock = true;
                ProtectProc = "noaccess";
                ProtectKernelLogs = true;
                ProtectKernelModules = true;
                ProtectKernelTunables = true;
                ProtectControlGroups = true;
                ProtectHostname = true;
                PrivateDevices = true;
                RestrictRealtime = true;
                RestrictNamespaces = true;
                LockPersonality = true;
                # Doesn't seem to work. Possibly due to C#
                MemoryDenyWriteExecute = false; 
                SystemCallFilter = [ "@system-service" "~@privileged" ];
              };
            };
          }
        )
        enabledServers;
    };
}
