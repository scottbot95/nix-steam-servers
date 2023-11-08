{
  perSystem = {
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
    };
  };
}
