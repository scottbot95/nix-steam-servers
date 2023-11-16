{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.nodes.server.services.steam-servers.stationeers.test;
in {
  name = "stationeers";

  nodes = {
    server = {
      virtualisation = {
        cores = 4;
        memorySize = 16 * 1024;
      };

      services.steam-servers.stationeers.test = {
        enable = true;
        serverPasswordPath = builtins.toFile "pass" "1234";
        adminPasswordPath = builtins.toFile "pass" "5678";
      };
    };
  };

  testScript = ''
    server.wait_for_unit("stationeers-test.service")
    server.wait_for_console_text("started Server ${toString cfg.config.GamePort}")
    server.succeed("test -d ${cfg.datadir}/saves/${cfg.worldName}")
  '';
}
