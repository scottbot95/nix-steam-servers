lib:
with lib; {
  mkOpt = type: default: description:
    mkOption {
      inherit type default;
      description = mdDoc description;
    };

  writeXML = name: value: let
    properies =
      mapAttrsToList
      (name: propVal: let
        encoded =
          if (builtins.typeOf propVal) == "bool"
          then boolToString propVal
          else toString propVal;
      in "<property name=\"${name}\" value=\"${encoded}\"/>")
      value;
    xml = ''
      <?xml version="1.0"?>
      <ServerSettings>
        ${concatStringsSep "\n  " properies}
      </ServerSettings>
    '';
  in
    builtins.toFile name xml;

  mkSymlinks = pkgs: name: symlinks:
    pkgs.writeShellScript "${name}-symlinks"
    (concatStringsSep "\n"
      (mapAttrsToList
        (n: v: ''
          if [[ -L "${n}" ]]; then
            unlink "${n}"
          elif [[ -e "${n}" ]]; then
            echo "${n} already exists, moving"
            mv "${n}" "${n}.bak"
          fi
          mkdir -p "$(dirname "${n}")"
          ln -sf "${v}" "${n}"
        '')
        symlinks));

  mkFiles = pkgs: name: files:
    pkgs.writeShellScript "${name}-files"
    (concatStringsSep "\n"
      (mapAttrsToList
        (n: v: ''
          if [[ -L "${n}" ]]; then
            unlink "${n}"
          elif ${pkgs.diffutils}/bin/cmp -s "${n}" "${v}"; then
            rm "${n}"
          elif [[ -e "${n}" ]]; then
            echo "${n} already exists, moving"
            mv "${n}" "${n}.bak"
          fi
          mkdir -p $(dirname "${n}")
          ${pkgs.gawk}/bin/awk '{
            for(varname in ENVIRON)
              gsub("@"varname"@", ENVIRON[varname])
            print
          }' "${v}" > "${n}"
        '')
        files));

  mkDirs = pkgs: name: dirs:
    pkgs.writeShellScript "${name}-dirs"
    (concatStringsSep "\n"
      (mapAttrsToList
        (n: v: ''
          if [[ -L "${n}" ]]; then
            unlink "${n}"
          elif [[ ! -d "${n}" ]]; then
            echo "${n} already exists and isn't a directory, moving"
            mv "${n}" "${n}.bak"
          fi
          ${pkgs.rsync}/bin/rsync -avu "${v}" "${n}"
        '')
        dirs));
}
