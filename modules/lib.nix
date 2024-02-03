lib:
with lib; let
  formatExtensions = with pkgs.formats; {
    "yml" = yaml {};
    "yaml" = yaml {};
    "json" = json {};
    "props" = keyValue {};
    "properties" = keyValue {};
    "toml" = toml {};
    "ini" = ini {};
  };

  inferFormat = name: let
    error = throw "nix-steam-servers: Could not infer format from file '${name}'. Specify one using 'format'.";
    extension = builtins.match "[^.]*\\.(.+)" name;
  in
    if extension != null && extension != []
    then formatExtensions.${head extension} or error
    else error;
  getFormat = name: config:
    if config ? format && config.format != null
    then config.format
    else inferFormat name;
  configToPath = name: config:
    if isStringLike config # Includes paths and packages
    then config
    else (getFormat name config).generate name config.value;

  nonEmpty = x: x != {} && x != [];
  nonEmptyValue = x: nonEmpty x && (x ? value -> nonEmpty x.value);
  normalizeFiles = files: mapAttrs configToPath (filterAttrs (_: nonEmptyValue) files);

  configType = types.submodule {
    options = {
      format = mkOption {
        type = with types; nullOr attrs;
        default = null;
        description = ''
          The format to use when converting "value" into a file. If set to
          null (the default), we'll try to infer it from the file name.
        '';
        example = literalExpression "pkgs.formats.yaml { }";
      };
      value = mkOption {
        type = with types; either (attrsOf anything) (listOf anything);
        description = ''
          A value that can be converted into the specified format.
        '';
      };
    };
  };
in {
  inherit normalizeFiles configType;

  mkOpt = type: default: description:
    mkOption {
      inherit type default;
      description = mdDoc description;
    };

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
          ${pkgs.rsync}/bin/rsync -avu "${v}/" "${n}"
          chmod -R u+w "${n}"
        '')
        dirs));
}
