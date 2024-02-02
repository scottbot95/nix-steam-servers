{lib, ...}:
with lib; {
  name = "palworld";

  nodes = {
    server = {
      virtualisation = {
        cores = 8;
        memorySize = 16 * 1024;
        diskSize = 8 * 1024;

        forwardPorts = [
          {
            from = "guest";
            guest.port = 8211;
            guest.address = "10.0.2.10";
            host.port = 8211;
            host.address = "0.0.0.0";
          }
        ];
      };

      services.steam-servers.palworld.test = {
        enable = true;
        openFirewall = true;
      };
    };
  };

  testScript = ''
    server.wait_for_unit("palworld-test.service")
  '';
}
