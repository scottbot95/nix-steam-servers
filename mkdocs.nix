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

    options-doc = let
      eachOptions = with lib;
        filterAttrs
        (_: hasSuffix "options.nix")
        (flattenTree {tree = rakeLeaves ./modules;});

      eachOptionsDoc = with lib;
        mapAttrs' (
          name: value: let 
            isTopLevel = name == "options";
            trimmedName =
              if isTopLevel then 
                "toplevel"
              else
                (head (splitString "." name));
            modules = (optionals (!isTopLevel) [baseOptionsModule]) ++ [value];
          in nameValuePair
            trimmedName
            # generate options doc
            (pkgs.nixosOptionsDoc { options = evalModules { inherit modules; }; })
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

      buildInput = [ options-doc ];
      nativeBuildInputs = [ mdbook ];

      phases = [ "buildPhase" "installPhase" ];

      buildPhase = ''
        ln -s ${options-doc} ${docsPath}
        mdbook build
      '';

      installPhase = ''
        mv book $out
      '';

      passthru.serve = pkgs.writeShellScriptBin "server" ''
        set -euo pipefail

        # link in options reference
        rm -f ${docsPath}
        ln -s ${options-doc} ${docsPath} # TODO auto-update this somehow...

        ${mdbook}/bin/mdbook serve "$@"
      '';
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