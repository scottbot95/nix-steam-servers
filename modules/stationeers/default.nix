{
  config,
  lib,
  ...
}:
with lib; let
  baseCfg = config.services.steam-servers;
  cfg = baseCfg.stationeers;
  enabledServers = filterAttrs (_: conf: conf.enable) cfg;

  writeXML = name: value: let
    nonNull =
      filterAttrs
      (_: v: v != null)
      value;
    properies =
      mapAttrsToList
      (name: propVal: let
        encoded =
          if (builtins.typeOf propVal) == "bool"
          then boolToString propVal
          else toString propVal;
      in "<${name}>${encoded}</${name}>")
      nonNull;
    xml = ''
      <?xml version="1.0"?>
      <SettingData>
        ${concatStringsSep "\n  " properies}
      </SettingData>
    '';
  in
    builtins.toFile name xml;
in {
  imports = [./options.nix];

  config = mkIf (enabledServers != {}) {
    networking.firewall =
      mkMerge
      (map
        (conf:
          mkIf conf.openFirewall {
            allowedUDPPorts = [conf.config.UpdatePort conf.config.GamePort];
            allowedTCPPorts = [8081]; # Meta server port? Not sure what this is for
          })
        (builtins.attrValues enabledServers));

    systemd.tmpfiles.rules = [
      "d ${baseCfg.datadir}/stationeers 0750 ${baseCfg.user} ${baseCfg.group} - -"
    ];

    services.steam-servers.servers =
      mapAttrs'
      (name: conf: let
        settingsFile = writeXML "settings.xml" conf.config;
        # cliSettings =
        #   (optionals (conf.serverPasswordPath != null) ["ServerPassword" ''"$(cat "$CREDENTIALS_DIRECTORY/serverPass")"''])
        #   ++ (optionals (conf.adminPasswordPath != null) ["AdminPassword" ''"$(cat "$CREDENTIALS_DIRECTORY/adminPass")"'']);
        # settingsArgs =
        #   optionals
        #     (cliSettings != [])
        #     (["-settings"] ++ cliSettings);
        args =
          [
            "-batchmode"
            "-nographics"
            "-loadlatest"
            (escapeShellArg conf.worldName)
            (escapeShellArg conf.worldType)
            "-settingspath"
            "${conf.datadir}/settings.xml"
          ]
          # ++ settingsArgs # FIXME not sure why this breaks the server :(
          ++ (map escapeShellArg conf.extraArgs);
      in
        nameValuePair "stationeers-${name}" {
          inherit args;
          inherit (conf) enable datadir;

          files = {
            "settings.xml" = settingsFile;
          };

          executable = "${conf.package}/rocketstation_DedicatedServer.x86_64";
        })
      cfg;

    systemd.services =
      mapAttrs'
      (
        name: conf:
          nameValuePair "stationeers-${name}" {
            serviceConfig = {
              # Doesn't seem to work. Possibly due to C#
              MemoryDenyWriteExecute = false;

              LoadCredential =
                (optionals (conf.serverPasswordPath != null) ["serverPass:${conf.serverPasswordPath}"])
                ++ (optionals (conf.adminPasswordPath != null) ["adminPass:${conf.adminPasswordPath}"]);
            };
          }
      )
      enabledServers;
  };
}
