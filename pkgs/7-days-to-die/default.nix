{ lib
, stdenv
, fetchSteam
, autoPatchelfHook
, steamworks-sdk-redist
, gcc-unwrapped
, zlib
}:
stdenv.mkDerivation rec {
  name = "7-days-to-die-server";
  version = "21.2";
  src = fetchSteam {
    inherit name;
    appId = "294420";
    depotId = "294422";
    manifestId = " 4485042179748822610";
    # Fetch a different branch. <https://partner.steamgames.com/doc/store/application/branches>
    # branch = "beta_name";
    # Enable debug logging from DepotDownloader.
    # debug = true;
    hash = "sha256-S2xCAZj8/KPen2yKb10923ZS74cC8tNxu6qvICmwaH8=";
  };

  # Skip phases that don't apply to prebuilt binaries.
  dontBuild = true;
  dontConfigure = true;
  # dontFixup = true;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    steamworks-sdk-redist
    gcc-unwrapped
    zlib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r ./* $out

    # You may need to fix permissions on the main executable.
    chmod +x $out/startserver.sh $out/7DaysToDieServer.x86_64

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