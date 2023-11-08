{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.steam-servers;
in {
  options.services.steam-servers = {
    datadir = mkOption {
      type = types.path;
      default = "/var/lib/steam-servers";
      description = mdDoc ''
        Base directory for all steam servers created with this module.
      '';
      example = "/mnt/nfs/steam";
    };

    user = mkOption {
      type = types.str;
      default = "steam-server";
      description = mdDoc ''
        User to use when running steam servers and creating top-level resources
      '';
    };

    group = mkOption {
      type = types.str;
      default = cfg.user;
      defaultText = literalExpression "\${cfg.user}";
      description = mdDoc "Group to use when running steam servers";
    };
  };
}
