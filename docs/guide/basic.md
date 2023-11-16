# Basic Usage

The simplest use-case is one of the pre-defined opinionated modules
for a specific game. For example, creating a basic Stationeers server could look
something like this:

```nix
{ # configuration.nix
  services.steam-servers.servers = {
    services.steam-servers.stationeers.my-server = {
      enable = true;
      openFirewall = true;
      # Any customizations...
    };
  };
}
```