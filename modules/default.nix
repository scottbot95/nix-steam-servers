args @ {inputs, ...}: let
  modules = {
    "7-days-to-die" = import ./7-days-to-die args;
    "servers" = import ./servers args;
  }; # TODO use rakeLeaves
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
