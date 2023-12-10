{inputs, ...}: {
  perSystem = {
    config,
    system,
    # pkgs,
    # pkgsUnstable,
    ...
  }: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    devshells.default = {
      name = "nix-steam-servers";
      packages = with pkgs; [
        nix-update
        mdbook
        deno
        steamcmd
      ];
      commands = [
        {
          category = "Tools";
          name = "update-servers";
          help = "Helper to check for updates";
          command = "nix run .#update-servers -- \"$@\"";
        }
      ];
      devshell.startup = {
        pre-commit-hook.text = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
  };
}
