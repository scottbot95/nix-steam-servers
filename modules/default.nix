args @ {inputs, ...}: let
  modules = {
    "7-days-to-die" = import ./7-days-to-die args;
  };
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
        (game:
          any
          (serverConf: serverConf.enable)
          (builtins.attrValues cfg.${game}))
        (builtins.attrNames modules);
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

        systemd.tmpfiles.rules = [
          "d ${cfg.datadir} 775 steam-server steam-server"
        ];

        users.users.${cfg.user} = {
          isSystemUser = true;
          home = "${cfg.datadir}";
          group = "${cfg.group}";
        };

        users.groups.${cfg.group} = {};
      };
    };
}
