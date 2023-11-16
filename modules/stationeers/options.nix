{
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
      enable = mkEnableOption (mdDoc "Stationeers Dedicated Server");

      package = mkOption {
        type = types.package;
        default = pkgs.stationeers;
        defaultText = literalExpression "pkgs.stationeers";
        description = mdDoc "Package to use for Stationeers binary";
      };

      datadir = mkOption {
        type = types.path;
        default = "${baseCfg.datadir}/stationeers/${name}";
        defaultText = literalExpression "\${services.steam-servers.datadir}/stationeers/\${name}";
        description = mdDoc ''
          Directory to store save state of the game server. (eg world, saves, etc)
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to open ports in the firewall. Does not open telnet/admin ports";
      };

      difficulty = mkOption {
        type = types.str;
        default = "normal";
        description = mdDoc "Difficulty setting to use when creating worlds";
      };

      worldName = mkOption {
        type = types.str;
        default = name;
        defaultText = literalExpression "\${name}";
        description = mdDoc ''
          Name of the save game to use. A new world of type `worldType` will be
          created of save does not exist.
        '';
      };

      worldType = mkOpt types.str "mars" ''
        World type to use when creating a new world.

        Must be one of moon, mars, europa, europa2, mimas, vulcan, vulcan2, space, loulan, venus
        or a mod-provided value
      '';

      serverPasswordPath = mkOpt (types.nullOr types.str) null ''
        Path to a secret file containing a password required to connect to the server.

        Can be `null` for no password.
      '';

      adminPasswordPath = mkOpt (types.nullOr types.str) null ''
        Path to a secret file containing a password required to connect to RCON.

        Can be `null` for no RCON support.
      '';

      config = {
        AutoSave = mkOpt types.bool true "Whether to enable autosaving of the server";
        SaveInterval = mkOpt types.int 300 "Auto-save interval (in seconds)";
        SavePath = mkOpt types.path "${config.datadir}" "Path to world saves directory";
        StartingConditions = mkOpt types.str "Default" "Default, Minimal, Vulcan, Venus, BareBones, or mod provided. (possible ignored by server)";
        RespawnCondition = mkOpt types.str "Easy" "Easy, Normal, Stationeers, or mod provided";
        HungerRate = mkOpt types.number 0.5 "Rate at which hungre drains";
        SunOrbitPeriod = mkOpt types.number 1 "Multiplier on the time it takes for the sun to orbit, default is 20 minutes, 10 minute day 10 night.";
        ResearchPoolKey = mkOpt types.str "ResearchOn" "ResearchOff, ResearchOn, or a custom key from a mod";
        RoomControlTickSpeed = mkOpt types.number 1 "";
        WorldOrigin = mkOpt types.bool false "";
        ServerName = mkOpt types.str "Stationeers" "Name of the server shown to clients";
        StartLocalHost = mkOpt types.bool true "";
        LocalIpAddress = mkOpt types.str "0.0.0.0" "Local address to bind game server to";
        ServerVisible = mkOpt types.bool false "Whether or not server is publicly discoverable";
        ServerMaxPlayers = mkOpt types.int 10 "Max number of simultaneous players on the server";
        UpdatePort = mkOpt types.port 27015 "Steam update port";
        GamePort = mkOpt types.port 27016 "Game port";
        UPNPEnabled = mkOpt types.bool false "Whether to enable UPnP. Not recommended as enabling UPnP is inherently a security risk";
        DisconnectTimeout = mkOpt types.int 10000 "";
        NetworkDebugFrequency = mkOpt types.int 500 "";
      };

      extraConfig = mkOpt types.attrs {} "Extra config to add to the settings.xml";

      extraArgs = mkOpt (with types; listOf str) [] "Extra command line arguments to pass to the server";
    };
  };
in {
  options.services.steam-servers.stationeers = mkOption {
    type = types.attrsOf (types.submodule serverModule);
    default = {};
    description = mdDoc ''
      Options to configure one or more Stationers servers.
    '';
  };
}
