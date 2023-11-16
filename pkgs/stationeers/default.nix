{
  lib,
  stdenv,
  fetchSteam,
  autoPatchelfHook,
  gcc-unwrapped,
  zlib,
}:
stdenv.mkDerivation rec {
  name = "stationeers-server";
  version = "0.2.4297.19997";
  src = fetchSteam {
    inherit name;
    appId = "600760";
    depotId = "600762";
    manifestId = "6111669730390933276";
    hash = "sha256-86F/J12BqGN29NushOo3aXHzLpz4gFZOW7D0rkA0dTs=";
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
    chmod a+x -R $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "7 Days to Die dedicated server";
    homepage = "https://steamdb.info/app/600760/";
    changelog = "https://store.steampowered.com/news/app/544550?updates=true";
    sourceProvenance = with sourceTypes; [
      binaryNativeCode # Steam games are always going to contain some native binary component.
      binaryBytecode # e.g. Unity games using C#
    ];
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };
}
