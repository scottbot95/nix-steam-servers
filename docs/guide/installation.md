# Installation

## With flakes

Add nix-steam-servers to your `inputs`:
```nix
{ # flake.nix
  inputs = {
    steam-servers.url = "github:scottbot95/nix-steam-servers";
    steam-servers.inputs.nixpkgs.follows = "nixpkgs"; # Optional
  };
}
```

Include the exported nixos module in your configuration:
```nix
{ # configuration.nix
  imports = [
    inputs.steam-servers.nixosModules.default
  ];
}
```

## Without flakes

This repo is currently only avaiable with flakes.