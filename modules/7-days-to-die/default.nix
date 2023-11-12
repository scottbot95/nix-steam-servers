_: {
  config,
  lib,
  ...
}:
with lib; let
  baseCfg = config.services.steam-servers;
  cfg = config.services.steam-servers."7-days-to-die";

  writeXML = name: value: let
    properies =
      mapAttrsToList
      (name: propVal: let
        encoded =
          if (builtins.typeOf propVal) == "bool"
          then boolToString propVal
          else toString propVal;
      in "<property name=\"${name}\" value=\"${encoded}\"/>")
      value;
    xml = ''
      <?xml version="1.0"?>
      <ServerSettings>
        ${concatStringsSep "\n  " properies}
      </ServerSettings>
    '';
  in
    builtins.toFile name xml;
in {
  imports = [./options.nix];

  config = let
    enabledServers = filterAttrs (_: conf: conf.enable) cfg;
  in
    mkIf (enabledServers != {}) {
      networking.firewall = {
        allowedUDPPorts = flatten (map
          (conf: let
            basePort = conf.config.ServerPort;
          in
            optionals conf.openFirewall [basePort (basePort + 2)])
          (builtins.attrValues enabledServers));
      };

      systemd.services =
        mapAttrs'
        (
          name: _:
            nameValuePair "7-days-to-die-${name}" {
              serviceConfig = {
                # Doesn't seem to work. Possibly due to C#
                MemoryDenyWriteExecute = false;
              };
            }
        )
        enabledServers;

      services.steam-servers.servers =
        mapAttrs'
        (name: conf: let
          configFile = writeXML "serverconfig.xml" conf.config;
          args =
            [
              "-logfile"
              (
                if conf.logFile != null
                then conf.logFile
                else "${conf.datadir}/output_log__$(date +%Y-%m-%d__%H-%M-%S).txt"
              )
              "-quit"
              "-batchmode"
              "-nographics"
              "-dedicated"
              "-configfile=${configFile}"
            ]
            ++ conf.extraArgs;
          symlinks = {
            "${baseCfg.datadir}/.steam/sdk64/steamclient.so" = "${conf.package}/steamclient.so";

            "7DaysToDieServer.x86_64" = "${conf.package}/7DaysToDieServer.x86_64";
            "7DaysToDieServer_Data" = "${conf.package}/7DaysToDieServer_Data";
            "Data" = "${conf.package}/Data";
            "platform.cfg" = "${conf.package}/platform.cfg"; # TODO not sure if this one is needed
            "UnityPlayer.so" = "${conf.package}/UnityPlayer.so";
            "libstdc++.so.6" = "${conf.package}/libstdc++.so.6";
            "steamclient.so" = "${conf.package}/steamclient.so";
            "Mods" = "${conf.package}/Mods";
          };
        in
          nameValuePair "7-days-to-die-${name}" {
            inherit args symlinks;
            inherit (conf) enable;

            executable = "./7DaysToDieServer.x86_64";
          })
        cfg;
    };
}
