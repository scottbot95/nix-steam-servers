{
  lib,
  mkSteamPackage,
  gcc-unwrapped,
}:
mkSteamPackage {
  lockFile = ./lock.json;

  buildInputs = [
    gcc-unwrapped
  ];

  meta = with lib; {
    description = "Palworld Dedicated Server";
    homepage = "https://steamdb.info/app/2394010/";
    changelog = "https://store.steampowered.com/news/app/1623730?updates=true";
    sourceProvenance = with sourceTypes; [
      binaryNativeCode # Steam games are always going to contain some native binary component.
    ];
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };
}
