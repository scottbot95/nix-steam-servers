{
  lib,
  writeShellScriptBin,
  depotdownloader,
  deno,
}:
with lib; let
  runtimeDeps = [
    depotdownloader
  ];
  # Using ./. ensures all ts files get copied to the nix store
  mainPath = "${./.}/main.ts";
in
  writeShellScriptBin "updater" ''
    PATH=${makeBinPath runtimeDeps}:$PATH

    ${getExe deno} run -A ${mainPath} "$@"
  ''
