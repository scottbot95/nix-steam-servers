{
  perSystem = {
    config,
    pkgs,
    # pkgsUnstable,
    ...
  }: {
    devshells.default = {
      name = "nix-steam-servers";
      packages = with pkgs; [
        nix-update
        mdbook
      ];
      devshell.startup = {
        pre-commit-hook.text = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
  };
}
