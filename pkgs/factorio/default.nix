{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "factorio-headless";
  version = "2.0.72";

  src = fetchurl {
    name = "factorio_headless_x64-${version}.tar.xz";
    url = "https://www.factorio.com/get-download/${version}/headless/linux64";
    sha256 = "cf3057340dbc9d82bd5161949ae3e7b8fad912ec7ca07b8a3151e0424a5568cd";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  unpackPhase = ''
    tar xJf $src
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    cp -r factorio/* $out/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Factorio Headless Server";
    homepage = "https://www.factorio.com/";
    sourceProvenance = with sourceTypes; [
      binaryNativeCode
    ];
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };
}
