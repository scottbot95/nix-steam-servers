{ self, inputs, ... }:
{ config, pkgs, lib, ... }:
with lib;
let
  modulesLib = import ../lib.nix lib;
  inherit (modulesLib) writeXML;
  mkSymlinks = modulesLib.mkSymlinks pkgs;
  mkDirs = modulesLib.mkDirs pkgs;

  baseCfg = config.services.steam-servers;
  cfg = config.services.steam-servers."7-days-to-die";
  mkOpt = type: default: description: mkOption {
    inherit type default description;
  };
in
{
  options.services.steam-servers."7-days-to-die" = mkOption {
    type = types.attrsOf (types.submodule ({ config, name, ...}: {
      options = {
        enable = mkEnableOption "7 Day to Die Dedicated Server";

        package = mkOption {
          type = types.package;
          default = self.packages.${pkgs.system}."7-days-to-die";
          defaultText = literalExpression "flake.packages.7-days-to-die";
          description = mdDoc "Package to use for 7 Days to Die binary";
        };

        datadir = mkOption {
          type = types.path;
          default = "${baseCfg.datadir}/7-days-to-die/${name}";
          defaultText = literalExpression "\${services.steam-servers.datadir}/7-days-to-die/\${name}";
          description = mdDoc ''
            Directory to store save state of the game server. (eg world, saves, etc)
          '';
        };

        openFirewall = mkOption {
          type = types.bool;
          default = false;
          description = mdDoc "Whether to open ports in the firewall. Does not open telnet/admin ports";
        };

        config = {
          # <!-- Server representation -->
          ServerName = mkOpt types.str "My Game Host" "Whatever you want the name of the server to be.";
          ServerDescription = mkOpt types.str "A 7 Days to Die server" "you want the server description to be, will be shown in the server browser.";
          ServerWebsiteURL = mkOpt types.str "" "Website URL for the server, will be shown in the serverbrowser as a clickable link";
          ServerPassword = mkOpt types.str "" "Password to gain entry to the server";
          ServerLoginConfirmationText = mkOpt types.str "" "If set the user will see the message during joining the server and has to confirm it before continuing. For more complex changes to this window you can change the 'serverjoinrulesdialog' window in XUi";
          Region = mkOpt types.str "NorthAmericaEast" "region this server is in. Values: NorthAmericaEast, NorthAmericaWest, CentralAmerica, SouthAmerica, Europe, Russia, Asia, MiddleEast, Africa, Oceania";
          Language = mkOpt types.str "English" "Primary language for players on this server. Values: Use any language name that you would users expect to search for. Should be the English name of the language, e.g. not 'Deutsch' but 'German'";

          # <!-- Networking -->
          ServerPort = mkOpt types.port 26900 "Port you want the server to listen on. Keep it in the ranges 26900 to 26905 or 27015 to 27020 if you want PCs on the same LAN to find it as a LAN server.";
          ServerVisibility = mkOpt (types.ints.between 0 2) 0 "Visibility of this server: 2 = public, 1 = only shown to friends, 0 = not listed. As you are never friend of a dedicated server setting this to \"1\" will only work when the first player connects manually by IP.";
          ServerDisabledNetworkProtocols = mkOpt types.str "SteamNetworking" "protocols that should not be used. Separated by comma. Possible values: LiteNetLib, SteamNetworking. Dedicated servers should disable SteamNetworking if there is no NAT router in between your users and the server or when port-forwarding is set up correctly";
          ServerMaxWorldTransferSpeedKiBs = mkOpt types.int 512 "Maximum (!) speed in kiB/s the world is transferred at to a client on first connect if it does not have the world yet. Maximum is about 1300 kiB/s, even if you set a higher value.";

          # <!-- Slots -->
          ServerMaxPlayerCount = mkOpt types.int 8 "Maximum Concurrent Players";
          ServerReservedSlots = mkOpt types.int 0 "Out of the MaxPlayerCount this many slots can only be used by players with a specific permission level";
          ServerReservedSlotsPermission = mkOpt types.int 100 "Required permission level to use reserved slots above";
          ServerAdminSlots = mkOpt types.int 0 "This many admins can still join even if the server has reached MaxPlayerCount";
          ServerAdminSlotsPermission = mkOpt types.int 0 "Required permission level to use the admin slots above";

          # <!-- Admin interfaces -->
          WebDashboardEnabled = mkOpt types.bool false "Enable/disable the web dashboard";
          WebDashboardPort = mkOpt types.port 8080 "Port of the web dashboard";
          WebDashboardUrl = mkOpt types.str "" "External URL to the web dashboard if not just using the public IP of the server, e.g. if the web dashboard is behind a reverse proxy. Needs to be the full URL, like 'https://domainOfReverseProxy.tld:1234/'. Can be left empty if directly using the public IP and dashboard port";
          EnableMapRendering = mkOpt types.bool false "Enable/disable rendering of the map to tile images while exploring it. This is used e.g. by the web dashboard to display a view of the map.";

          TelnetEnabled = mkOpt types.bool true "Enable/Disable the telnet";
          TelnetPort = mkOpt types.port 8081 "Port of the telnet server";
          TelnetPassword = mkOpt types.str "" "Password to gain entry to telnet interface. If no password is set the server will only listen on the local loopback interface";
          TelnetFailedLoginLimit = mkOpt types.int 10 "After this many wrong passwords from a single remote client the client will be blocked from connecting to the Telnet interface";
          TelnetFailedLoginsBlocktime = mkOpt types.int 10 "How long will the block persist (in seconds)";

          TerminalWindowEnabled = mkOpt types.bool true "Show a terminal window for log output / command input (Windows only)";

          # <!-- Folder and file locations -->
          AdminFileName = mkOpt types.str "serveradmin.xml" "admin file name. Path relative to the SaveGameFolder";
          UserDataFolder = mkOpt types.str "${config.datadir}/UserData" "Use this to override where the server stores all generated data, including RWG generated worlds.";
          SaveGameFolder = mkOpt types.str "${config.config.UserDataFolder}/Saves" "Use this to only override the save game path.";

          # <!-- Other technical settings -->
          EACEnabled = mkOpt types.bool true "Enables/Disables EasyAntiCheat";
          HideCommandExecutionLog = mkOpt (types.ints.between 0 3) 0 "Hide logging of command execution. 0 = show everything, 1 = hide only from Telnet/ControlPanel, 2 = also hide from remote game clients, 3 = hide everything";
          MaxUncoveredMapChunksPerPlayer = mkOpt types.int 131072 "Override how many chunks can be uncovered on the ingame map by each player. Resulting max map file size limit per player is (x * 512 Bytes), uncovered area is (x * 256 m²). Default 131072 means max 32 km² can be uncovered at any time";
          PersistentPlayerProfiles = mkOpt types.bool false "If disabled a player can join with any selected profile. If true they will join with the last profile they joined with";



          # <!-- GAMEPLAY -->

          # <!-- World -->
          GameWorld = mkOpt types.str "Navezgane" (mdDoc ''
            "RWG" (see WorldGenSeed and WorldGenSize options below) or any already existing world name
            in the Worlds folder (currently shipping with e.g. "Navezgane", "PREGEN01", ...)
          '');
          WorldGenSeed = mkOpt types.str "asdf" "If RWG this is the seed for the generation of the new world. If a world with the resulting name already exists it will simply load it";
          WorldGenSize = mkOpt types.int 6144 "If RWG, this controls the width and height of the created world. Officially supported sizes are between 6144 and 10240 and must be a multiple of 2048, e.g. 6144, 8192, 10240.";
          GameName = mkOpt types.str "My Game" "Whatever you want the game name to be. This affects the save game name as well as the seed used when placing decoration (trees etc) in the world. It does not control the generic layout of the world if creating an RWG world";
          GameMode = mkOpt types.str "GameModeSurvival" "Game mode";

          # <!-- Difficulty -->
          GameDifficulty = mkOpt (types.ints.between 0 5) 1 "0=easiest, 5=hardest";
          BlockDamagePlayer = mkOpt types.int 100 "How much damage do players to blocks (percentage in whole numbers)";
          BlockDamageAI = mkOpt types.int 100 "How much damage do AIs to blocks (percentage in whole numbers)";
          BlockDamageAIBM = mkOpt types.int 100 "How much damage do AIs during blood moons to blocks (percentage in whole numbers)";
          XPMultiplier = mkOpt types.int 100 "XP gain multiplier (percentage in whole numbers)";
          PlayerSafeZoneLevel = mkOpt types.int 5 "If a player is less or equal this level he will create a safe zone (no enemies) when spawned";
          PlayerSafeZoneHours = mkOpt types.int 5 "Hours in world time this safe zone exists";

          # <!--  -->
          BuildCreate = mkOpt types.bool false "cheat mode on/off";
          DayNightLength = mkOpt types.int 60 "real time minutes per in game day";
          DayLightLength = mkOpt types.int 18 "in game hours the sun shines per day";
          DropOnDeath = mkOpt (types.ints.between 0 4) 1 "0 = nothing, 1 = everything, 2 = toolbelt only, 3 = backpack only, 4 = delete all";
          DropOnQuit = mkOpt (types.ints.between 0 3) 0 "0 = nothing, 1 = everything, 2 = toolbelt only, 3 = backpack only";
          BedrollDeadZoneSize = mkOpt types.int 15 ''Size (box "radius", so a box with 2 times the given value for each side's length) of bedroll deadzone, no zombies will spawn inside this area, and any cleared sleeper volumes that touch a bedroll deadzone will not spawn after they've been cleared.'';
          BedrollExpiryTime = mkOpt types.int 45 "Number of real world days a bedroll stays active after owner was last online";

          # <!-- Performance related -->
          MaxSpawnedZombies = mkOpt types.int 64 "This setting covers the entire map. There can only be this many zombies on the entire map at one time. Changing this setting has a huge impact on performance.";
          MaxSpawnedAnimals = mkOpt types.int 50 "If your server has a large number of players you can increase this limit to add more wildlife. Animals don't consume as much CPU as zombies. NOTE: That this doesn't cause more animals to spawn arbitrarily: The biome spawning system only spawns a certain number of animals in a given area, but if you have lots of players that are all spread out then you may be hitting the limit and can increase it.";
          ServerMaxAllowedViewDistance = mkOpt types.int 12 "Max viewdistance a client may request (6 - 12). High impact on memory usage and performance.";
          MaxQueuedMeshLayers = mkOpt types.int 1000 "Maximum amount of Chunk mesh layers that can be enqueued during mesh generation. Reducing this will improve memory usage but may increase Chunk generation time";

          # <!-- Zombie settings -->
          EnemySpawnMode = mkOpt types.bool true "Enable/Disable enemy spawning";
          EnemyDifficulty = mkOpt (types.enum [0 1]) 0 "0 = Normal, 1 = Feral";
          ZombieFeralSense = mkOpt (types.ints.between 0 3) 0 "0-3 (Off, Day, Night, All)";
          ZombieMove = mkOpt (types.ints.between 0 3) 0 "0-4 (walk, jog, run, sprint, nightmare)";
          ZombieMoveNight = mkOpt (types.ints.between 0 3) 3 "0-4 (walk, jog, run, sprint, nightmare)";
          ZombieFeralMove = mkOpt (types.ints.between 0 3) 3 "0-4 (walk, jog, run, sprint, nightmare)";
          ZombieBMMove = mkOpt (types.ints.between 0 3) 3 "0-4 (walk, jog, run, sprint, nightmare)";
          BloodMoonFrequency = mkOpt types.int 7 "What frequency (in days) should a blood moon take place. Set to '0' for no blood moons";
          BloodMoonRange = mkOpt types.int 0 "How many days can the actual blood moon day randomly deviate from the above setting. Setting this to 0 makes blood moons happen exactly each Nth day as specified in BloodMoonFrequency";
          BloodMoonWarning = mkOpt types.int 8 "The Hour number that the red day number begins on a blood moon day. Setting this to -1 makes the red never show. ";
          BloodMoonEnemyCount = mkOpt types.int 8 "This is the number of zombies that can be alive (spawned at the same time) at any time PER PLAYER during a blood moon horde, however, MaxSpawnedZombies overrides this number in multiplayer games. Also note that your game stage sets the max number of zombies PER PARTY. Low game stage values can result in lower number of zombies than the BloodMoonEnemyCount setting. Changing this setting has a huge impact on performance.";

          # <!-- Loot -->
          LootAbundance = mkOpt types.int 100 "percentage in whole numbers";
          LootRespawnDays = mkOpt types.int 7 "days in whole numbers";
          AirDropFrequency = mkOpt types.int 72 "How often airdrop occur in game-hours, 0 == never";
          AirDropMarker = mkOpt types.bool true "Sets if a marker is added to map/compass for air drops.";

          # <!-- Multiplayer -->
          PartySharedKillRange = mkOpt types.int 100 "The distance you must be within to receive party shared kill xp and quest party kill objective credit.";
          PlayerKillingMode = mkOpt types.int 3 "Player Killing Settings (0 = No Killing, 1 = Kill Allies Only, 2 = Kill Strangers Only, 3 = Kill Everyone)";

          # <!-- Land claim options -->
          LandClaimCount = mkOpt types.int 3 "Maximum allowed land claims per player.";
          LandClaimSize = mkOpt types.int 41 "Size in blocks that is protected by a keystone";
          LandClaimDeadZone = mkOpt types.int 30 "Keystones must be this many blocks apart (unless you are friends with the other player)";
          LandClaimExpiryTime = mkOpt types.int 7 "The number of real world days a player can be offline before their claims expire and are no longer protected";
          LandClaimDecayMode = mkOpt (types.ints.between 0 2) 0 "Controls how offline players land claims decay. 0=Slow (Linear) , 1=Fast (Exponential), 2=None (Full protection until claim is expired).";
          LandClaimOnlineDurabilityModifier = mkOpt types.int 4 "How much protected claim area block hardness is increased when a player is online. 0 means infinite (no damage will ever be taken). Default is 4x";
          LandClaimOfflineDurabilityModifier = mkOpt types.int 4 "How much protected claim area block hardness is increased when a player is offline. 0 means infinite (no damage will ever be taken). Default is 4x";
          LandClaimOfflineDelay = mkOpt types.int 0 "The number of minutes after a player logs out that the land claim area hardness transitions from online to offline. Default is 0";


          DynamicMeshEnabled = mkOpt types.bool true "Is Dynamic Mesh system enabled";
          DynamicMeshLandClaimOnly = mkOpt types.bool true "Is Dynamic Mesh system only active in player LCB areas";
          DynamicMeshLandClaimBuffer = mkOpt types.int 3 "Dynamic Mesh LCB chunk radius";
          DynamicMeshMaxItemCache = mkOpt types.int 3 "How many items can be processed concurrently, higher values use more RAM";

          TwitchServerPermission = mkOpt types.int 90 "Required permission level to use twitch integration on the server";
          TwitchBloodMoonAllowed = mkOpt types.bool false "If the server allows twitch actions during a blood moon. This could cause server lag with extra zombies being spawned during blood moon.";

          MaxChunkAge = mkOpt types.int (-1) "The number of in-game days which must pass since visiting a chunk before it will reset to its original state if not revisited or protected (e.g. by a land claim or bedroll being in close proximity).";
          SaveDataLimit = mkOpt types.int (-1) "The maximum disk space allowance for each saved game in megabytes (MB). Saved chunks may be forceably reset to their original states to free up space when this limit is reached. Negative values disable the limit.";
        };

        logFile = mkOpt types.str "${config.datadir}/output_log__`date +%Y-%m-%d__%H-%M-%S`.txt" "Logfile to output logs to";

        extraArgs = mkOpt (with types; listOf str) [] "Extra command line arguments to pass to the server";
      };
    }));
    default = { };
  };

  config =
    let
      enabledServers = filterAttrs (_: conf: conf.enable) cfg;
    in
    mkIf (enabledServers != {}) {
      networking.firewall = {
        allowedUDPPorts = flatten (map 
          (conf:
            let
              basePort = conf.config.ServerPort;
            in
              (optionals conf.openFirewall [basePort (basePort + 2)]))
          (builtins.attrValues enabledServers));
      };

      systemd.services = mapAttrs'
        (name: conf:
          let
            configFile = writeXML "serverconfig.xml" conf.config;
            args = [
              "-logfile"
              conf.logFile
              "-quit"
              "-batchmode"
              "-nographics" 
              "-dedicated" 
              "-configfile=${configFile}"
            ] ++ conf.extraArgs;
            symlinks = {
              "${baseCfg.datadir}/.steam/sdk64/steamclient.so" = "${conf.package}/steamclient.so";

              "7DaysToDieServer.x86_64" = "${conf.package}/7DaysToDieServer.x86_64";
              "7DaysToDieServer_Data"   = "${conf.package}/7DaysToDieServer_Data";
              "Data"                    = "${conf.package}/Data";
              "platform.cfg"            = "${conf.package}/platform.cfg"; # TODO not sure if this one is needed
              "UnityPlayer.so"          = "${conf.package}/UnityPlayer.so";
              "libstdc++.so.6"          = "${conf.package}/libstdc++.so.6";
              "steamclient.so"          = "${conf.package}/steamclient.so";
              "Mods"                    = "${conf.package}/Mods";
            };
          in
          {
            name = "7-days-to-die-${name}";
            value = rec {
              description = "7 Days to Die Server ${name}";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];

              # enable = false;

              script = ''
                cd ${conf.datadir}
                ${conf.datadir}/7DaysToDieServer.x86_64 ${concatStringsSep " \\\n" args}
              '';

              preStart = ''
                umask u=rwx,g=rx,o=rx
                mkdir -p ${conf.datadir}
                mkdir -p ${baseCfg.datadir}/.steam/sdk64

                cd ${conf.datadir}

                ${mkSymlinks "7-days-to-die-${name}" symlinks}
              '';

              postStop =
                let
                  rmSymlinks = pkgs.writeShellScript "7-days-to-die-${name}-rm-symlinks"
                    (concatStringsSep "\n"
                      (mapAttrsToList (n: v: "unlink \"${n}\"") symlinks)
                    );
                in
                ''
                  cd ${conf.datadir}

                  ${rmSymlinks}
                '';

              serviceConfig = {
                Restart = "on-failure";
                User = "${baseCfg.user}";
                Group = "${baseCfg.group}";

                ProtectClock = true;
                ProtectProc = "noaccess";
                ProtectKernelLogs = true;
                ProtectKernelModules = true;
                ProtectKernelTunables = true;
                ProtectControlGroups = true;
                ProtectHostname = true;
                PrivateDevices = true;
                RestrictRealtime = true;
                RestrictNamespaces = true;
                LockPersonality = true;
                # Doesn't seem to work. Possibly due to C#
                MemoryDenyWriteExecute = false; 
                SystemCallFilter = [ "@system-service" "~@privileged" ];
              };
            };
          }
        )
        enabledServers;
    };
}
