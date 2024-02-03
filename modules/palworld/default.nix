{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  baseCfg = config.services.steam-servers;
  cfg = baseCfg.palworld;
  enabledServers = filterAttrs (_: conf: conf.enable) cfg;
  # settingsFormat = pkgs.formats.ini {};
  settingsFormat = {
    generate = name: value: let
      optionSettings =
        mapAttrsToList
        (optName: optVal: let
          optType = builtins.typeOf optVal;
          encodedVal =
            if optType == "string"
            then "\"${optVal}\""
            else if optType == "bool"
            then
              if optVal
              then "True"
              else "False"
            else optVal;
        in "${optName}=${encodedVal}")
        value;
    in
      builtins.toFile name ''
        [/Script/Pal.PalGameWorldSettings]
        OptionSettings=(${concatStringsSep "," optionSettings})
      '';
  };
in {
  imports = [./options.nix];

  config = mkIf (enabledServers != {}) {
    networking.firewall =
      mkMerge
      (map
        (conf:
          mkIf conf.openFirewall {
            # allowedUDPPorts = [conf.config.UpdatePort conf.config.GamePort];
            allowedUDPPorts = [8211];
          })
        (builtins.attrValues enabledServers));

    services.steam-servers.servers =
      mapAttrs'
      (name: conf: let
        settingsFile = settingsFormat.generate "PalWorldSettings.ini" conf.worldSettings;
      in
        nameValuePair "palworld-${name}" {
          # inherit args;
          inherit (conf) enable datadir;

          dirs = {
            Pal = "${conf.package}/Pal";
            Engine = "${conf.package}/Engine";
          };

          files = {
            # Copy start script since it derefernces symlinks to find the server root dir
            "PalServer.sh" = "${conf.package}/PalServer.sh";

            "Pal/Saved/Config/LinuxServer/PalWorldSettings.ini" = settingsFile;
          };

          executable = "chmod +x ${conf.datadir}/PalServer.sh; ${pkgs.steam-run}/bin/steam-run ${conf.datadir}/PalServer.sh";

          args =
            [
              "-port=${toString conf.port}"
              "-useperfthreads"
              "-NoAsyncLoadingThread"
              "-UseMultithreadForDS"
            ]
            ++ conf.extraArgs;
        })
      cfg;

    systemd.services =
      mapAttrs'
      (
        name: _conf:
          nameValuePair "palworld-${name}" {
            path = with pkgs; [
              xdg-user-dirs
            ];

            serviceConfig = {
              # Palworld needs namespaces and system calls
              RestrictNamespaces = false;
              SystemCallFilter = [];
            };
          }
      )
      enabledServers;
  };
}
