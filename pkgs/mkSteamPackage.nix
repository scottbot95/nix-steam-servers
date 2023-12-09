{
  lib,
  stdenv,
  fetchSteam,
  autoPatchelfHook,
  ...
}: args @ {lockFile, ...}: let
  lockData = lib.importJSON lockFile;
  inherit (lockData) appId depotId name;

  mkDerivationArgs = builtins.removeAttrs args ["lockFile"];

  mkSinglePackage = {
    manifestId,
    hash,
    version,
    ...
  }:
    stdenv.mkDerivation (rec {
        inherit version;
        pname = name;
        src = fetchSteam {
          inherit name appId depotId manifestId hash;
        };

        # Skip phases that don't apply to prebuilt binaries.
        dontBuild = true;
        dontConfigure = true;

        nativeBuildInputs = [
          autoPatchelfHook
        ];

        installPhase = ''
          runHook preInstall

          mkdir -p $out
          mv ./* $out

          # Probably not ideal but steamcmd sets all files to 755 so copy that behavior
          chmod 755 -R $out

          runHook postInstall
        '';
      }
      // mkDerivationArgs);

  builds =
    lib.mapAttrs
    (_buildId: mkSinglePackage)
    lockData.builds;

  branches =
    lib.mapAttrs
    (_branch: buildId: builds.${buildId})
    lockData.branches;
in
  branches.public
  // {
    # TODO is there a better way to vend all versions?
    inherit builds branches;
  }
