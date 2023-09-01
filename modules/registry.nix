  {nixpkgs, nixpkgs-unstable, ... }:
  {
    nix.registry = {
      # Make nixpkgs registry entry point to this flakes version
      nixpkgs.flake = nixpkgs;
      nixpkgs-unstable.flake = nixpkgs-unstable;
    };
  }
