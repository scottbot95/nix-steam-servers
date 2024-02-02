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
      (name: conf:
        nameValuePair "palworld-${name}" {
          # inherit args;
          inherit (conf) enable datadir;

          symlinks = {
            "${baseCfg.datadir}/.steam/sdk64/steamclient.so" = "${pkgs.steamworks-sdk-redist}/lib/steamclient.so";
            "Pal/Binaries" = "${conf.package}/Pal/Binaries";
            "Pal/Content" = "${conf.package}/Pal/Content";
            "Pal/Plugins" = "${conf.package}/Pal/Plugins";
            Engine = "${conf.package}/Engine";
          };

          dirs = {
          };

          files = {
            # Copy start script since it derefernces symlinks to find the server root dir
            "PalServer.sh" = "${conf.package}/PalServer.sh";
            # "Pal/Saved/Config/LinuxServer/PalWorldSettings.ini" = settingsFile;
          };

          executable = "./PalServer.sh";
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
          }
      )
      enabledServers;
  };
}
