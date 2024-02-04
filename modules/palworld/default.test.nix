{lib, ...}:
with lib; {
  name = "palworld";

  nodes = {
    server = {
      virtualisation = {
        cores = 8;
        memorySize = 16 * 1024;
        diskSize = 8 * 1024;
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
