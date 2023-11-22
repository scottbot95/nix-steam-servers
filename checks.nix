{
  perSystem = {
    pre-commit = {
      # Don't create a flake check since we already have flake checks for the same thing
      check.enable = false;
      settings = {
        hooks = {
          treefmt.enable = true;
        };
      };
    };
  };
}
