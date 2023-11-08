{lib, ...}:
with lib; {
  name = "7-days-to-die";

  nodes = {
    server = {
      virtualisation = {
        cores = 2;
        memorySize = 4096;
      };

      services.steam-servers."7-days-to-die".test = {
        enable = true;
        logFile = ">(systemd-cat)"; # useful so server logs show up in nix log
      };
    };
  };

  testScript = ''
    server.wait_for_unit("7-days-to-die-test")
    server.wait_for_open_port(26900)
  '';
}
