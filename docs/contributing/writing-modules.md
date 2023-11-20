# Writing Server Modules

## Tenets

The primary goal of the opinionated server modules is to provide a more ergonomic way
to create and manage servers of a specifc game. To that end, you should adhere to the
following tenets:

- Modules shoud be easy to use
- Modules should be secure by default
- Whenever possible, modules should allow running multiple servers on the same host

## Guidelines

From these tenets, we can conclude several guidelines:

- Modules should generally be an attribute set of server options to allow running multiple instances
- Default config values should provide a working server
  - Ideally, a user consuming a server would simply need to write `services.steam-servers.some-game.my-server.enable = true;`
- Default config values should provide a secure starting point
  - Don't automatically open firewall ports
  - Don't automatically list server on public listings (when support by the game)
- It should be easy to extend the CLI args/server config file generated

## Templates

The following templates are some useful starting points for creating new modules.
Make sure to replace `<game>` with the actual name of the game


#### modules/&lt;game&gt;/options.nix
```nix
{ # modules/<game>/options.nix
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  baseCfg = config.services.steam-servers;
  moduleLib = import ../lib.nix lib;
  inherit (moduleLib) mkOpt;

  serverModule = {
    config,
    name,
    ...
  }: {
    options = {
      enable = mkEnableOption (mdDoc "<game> Dedicated Server");

      package = mkOption {
        type = types.package;
        default = pkgs.<game>;
        defaultText = literalExpression "pkgs.<game>";
        description = mdDoc "Package to use for <game> binary";
      };

      datadir = mkOption {
        type = types.path;
        default = "${baseCfg.datadir}/<game>/${name}";
        defaultText = literalExpression "\${services.steam-servers.datadir}/<game>/\${name}";
        description = mdDoc ''
          Directory to store save state of the game server. (eg world, saves, etc)
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to open ports in the firewall";
      };

      config = {
        # Config options
      };

      extraConfig = mkOpt types.attrs {} "Extra config to add to the server config";

      extraArgs = mkOpt (with types; listOf str) [] "Extra command line arguments to pass to the server";
    };
  };
in {
  options.services.steam-servers.<game> = mkOption {
    type = types.attrsOf (types.submodule serverModule);
    default = {};
    description = mdDoc ''
      Options to configure one or more <game> servers.
    '';
  };
}

```

#### modules/&lt;game&gt;/default.nix
```nix
{ # modules/<game>/default.nix
  config,
  lib,
  ...
}:
with lib; let
  baseCfg = config.services.steam-servers;
  cfg = baseCfg.stationeers;
  enabledServers = filterAttrs (_: conf: conf.enable) cfg;
in {
  imports = [./options.nix];

  config = mkIf (enabledServers != {}) {
    networking.firewall =
      mkMerge
      (map
        (conf:
          mkIf conf.openFirewall {
            allowedUDPPorts = [conf.config.UpdatePort conf.config.GamePort];
          })
        (builtins.attrValues enabledServers));

    services.steam-servers.servers =
      mapAttrs'
      (name: conf: let
        args =
          [
            # Disable UI in unity
            "-batchmode"
            "-nographics"
          ]
          ++ (map escapeShellArg conf.extraArgs);
      in
        nameValuePair "<game>-${name}" {
          inherit args;
          inherit (conf) enable datadir;

          symlinks = {
            "settings.ini".value = conf.config;
          };

          executable = "${conf.package}/server_executable";
        })
      cfg;
  };
}
```

#### modules/&lt;game&gt;/default.test.nix
```nix
# modules/<game>/default.test.nix
{lib, ...}:
with lib; {
  name = "<game>";

  nodes = {
    server = {
      virtualisation = {
        cores = 2;
        memorySize = 4096;
      };

      services.steam-servers."<game>".test = {
        enable = true;
        # Any other config needed for a meaningful test
      };
    };
  };

  testScript = ''
    server.wait_for_unit("<game>-test.service")
    server.wait_for_open_port(26900) # Can only check TCP ports

    # Wait for some text in the syslog that indicates server started
    server.wait_for_console_text("started <game> Server")

    # Check save file has been created
    server.succeed("test -d ${cfg.datadir}/saves/${cfg.worldName}")
  '';
}

```
