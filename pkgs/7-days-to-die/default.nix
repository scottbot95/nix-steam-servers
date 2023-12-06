{
  lib,
  stdenv,
  fetchSteam,
  autoPatchelfHook,
  gcc-unwrapped,
  zlib,
}:
stdenv.mkDerivation rec {
  name = "7-days-to-die-server";
  version = "21.2";
  src = fetchSteam {
    inherit name;
    appId = "294420";
    depotId = "294422";
    manifestId = "1977371197884973023";
    # Fetch a different branch. <https://partner.steamgames.com/doc/store/application/branches>
    # branch = "beta_name";
    # Enable debug logging from DepotDownloader.
    # debug = true;
    hash = "sha256-occY0s1Co05Jw+SiK4VwXS3RsL2SceKVNVqnLo+vTDE=";
  };

  # Skip phases that don't apply to prebuilt binaries.
  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    gcc-unwrapped
    zlib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    mv ./* $out

    # You may need to fix permissions on the main executable.
    chmod +x \
      $out/startserver.sh \
      $out/7DaysToDieServer.x86_64

    runHook postInstall
  '';

  meta = with lib; {
    description = "7 Days to Die dedicated server";
    homepage = "https://steamdb.info/app/294420/";
    changelog = "https://store.steampowered.com/news/app/251570?updates=true";
    sourceProvenance = with sourceTypes; [
      binaryNativeCode # Steam games are always going to contain some native binary component.
      binaryBytecode # e.g. Unity games using C#
    ];
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };
}
