{
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    inherit (pkgs) stdenv mdbook;

    # Options needed by other modules for defaults.
    # All options should be marked as hidden from docs as they are properly documented seperately
    baseOptionsModule = {
      options.services.steam-servers = {
        datadir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/steam-servers";
          visible = false;
        };
      };
    };

    eachOptions = with lib; 
      filterAttrs
      (_: hasSuffix "options.nix")
      (flattenTree {tree = rakeLeaves ./modules;});

    book-summary = with lib;
      let 
        notTopLevel = filterAttrs (n: _: n != "options") eachOptions;
        modules = mapAttrsToList 
          (n: _: { name = "${head (splitString "." n)}"; } )
          notTopLevel;
      in templateFile pkgs "SUMMARY.md" ./docs/SUMMARY.md.mustache {
        inherit modules;
      };

    options-doc = let
      eachOptionsDoc = with lib;
        mapAttrs' (
          name: value: let
            isTopLevel = name == "options";
            trimmedName =
              if isTopLevel
              then "toplevel"
              else (head (splitString "." name));
            modules = (optionals (!isTopLevel) [baseOptionsModule]) ++ [value];
          in
            nameValuePair
            trimmedName
            # generate options doc
            (pkgs.nixosOptionsDoc {options = evalModules {inherit modules;};})
        )
        eachOptions;

      statements = with lib;
        concatStringsSep "\n"
        (mapAttrsToList (n: v: ''
            path=$out/${n}.md
            cat ${v.optionsCommonMark} >> $path
          '')
          eachOptionsDoc);
    in
      pkgs.runCommand "nixos-options" {} ''
        mkdir $out
        ${statements}
      '';

    docsPath = "./docs/reference/module-options";
  in {
    packages.docs = stdenv.mkDerivation {
      src = ./.;
      name = "nix-steam-servers-docs";

      buildInput = [options-doc];
      nativeBuildInputs = [mdbook];

      # Skip phases that don't matter
      dontConfigure = true;
      dontFixup = true;

      buildPhase = ''
        ln -s ${book-summary} ./docs/SUMMARY.md
        ln -s ${options-doc} ${docsPath}
        mdbook build
      '';

      installPhase = ''
        mv book $out
      '';

      passthru = {
        inherit options-doc;

        serve = pkgs.writeShellScriptBin "server" ''
          set -euo pipefail

          # link in options reference
          rm -f ${docsPath} ./docs/SUMMARY.md
          ln -s ${book-summary} ./docs/SUMMARY.md
          ln -s ${options-doc} ${docsPath} # TODO auto-update this somehow...

          ${mdbook}/bin/mdbook serve "$@"
        '';
      };
    };

    devshells.default.commands = let
      category = "Docs";
    in [
      {
        inherit category;
        name = "docs-serve";
        help = "Serve docs";
        command = "nix run .#docs.serve -- \"$@\"";
      }
      {
        inherit category;
        name = "docs-build";
        help = "Build docs";
        command = "nix build .#docs";
      }
    ];
  };
}
