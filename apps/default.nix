{lib, ...}: {
  perSystem = {pkgs, ...}: {
    apps.update-servers.program = let
      updater = pkgs.callPackage ./updater {};
    in "${lib.getExe updater}";
  };
}
