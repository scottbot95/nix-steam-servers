{
  self,
  inputs,
  lib,
  ...
}: let
  eachModule = with lib;
    filterAttrs
    (name: file: (name != "default") && (hasSuffix "default.nix" file))
    (flattenTree {tree = rakeLeaves ./.;});

  modules = with lib;
    mapAttrs'
    (name:
      nameValuePair
      (removeSuffix ".default" name))
    eachModule;
in {
  imports = [
    ./testing.nix
  ];

  flake.nixosModules.default = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.services.steam-servers;
      anyServersEnabled =
        any
        (conf: conf.enable)
        (builtins.attrValues cfg.servers);
    in {
      imports =
        [
          ./options.nix
        ]
        ++ (builtins.attrValues modules);

      config = mkIf anyServersEnabled {
        nixpkgs.overlays = [
          self.overlays.default
          inputs.steam-fetcher.overlays.default
        ];

        # Can't use tmpfiles because tmpfiles won't create directories with different owner than parent
        systemd.services."make-steam-servers-dir" = let
          services =
            map
            (name: "${name}.service")
            (builtins.attrNames cfg.servers);
        in {
          wantedBy = services;
          before = services;

          script = ''
            mkdir -p ${cfg.datadir}
            chown ${cfg.user}:${cfg.group} ${cfg.datadir}
          '';

          serviceConfig = {
            Type = "oneshot";
          };
        };

        users.users.${cfg.user} = {
          isSystemUser = true;
          home = "${cfg.datadir}";
          group = "${cfg.group}";
        };

        users.groups.${cfg.group} = {};
      };
    };
}
