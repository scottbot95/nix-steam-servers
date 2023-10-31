{ pkgs, lib, ... }:
with lib;
{
  name = "7-days-to-die";

  nodes = {
    server = {
      virtualisation = {
        cores = 2;
        memorySize = 8192;
      };

      services.steam."7-days-to-die".servers.test = {
        enable = true;
      };
    };
  };

  testScript = ''
    server.wait_for_unit("7-days-to-die-test")
    server.wait_for_open_port(8081)
  '';
}