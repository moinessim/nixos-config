{
  description = "NixOS systems and tools";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";

      # We want to use the same set of nixpkgs as our system.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";

      # We want to use the same set of nixpkgs as our system.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, darwin, ... }@inputs: let

    mkDarwin = import ./lib/mkdarwin.nix;
    mkVM = import ./lib/mkvm.nix;

    additionalModules = [
      (import ./modules/registry.nix inputs)
      ./modules/grafana.nix
    ];

    # Overlays is the list of overlays we want to apply from flake inputs.
    overlays = [
    ];
  in {
    nixosConfigurations.vm-aarch64 = mkVM "vm-aarch64" {
      inherit nixpkgs home-manager additionalModules;
      system = "aarch64-linux";
      user   = "moisesnessim";

      overlays = overlays ++ [(final: prev: {
        # Example of bringing in an unstable package:
        # open-vm-tools = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.open-vm-tools;

        inherit (
            inputs.nixpkgs-unstable.legacyPackages.${prev.system}
            .callPackage ./pkgs/fsautocomplete.nix {})
          fsautocomplete fsautocomplete-local-or-nix;
        nixd = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.nixd;

      })];
    };

    nixosConfigurations.vm-aarch64-prl = mkVM "vm-aarch64-prl" {
      inherit overlays nixpkgs home-manager additionalModules;
      system = "aarch64-linux";
      user   = "moisesnessim";
    };

    nixosConfigurations.vm-aarch64-utm = mkVM "vm-aarch64-utm" {
      inherit overlays nixpkgs home-manager additionalModules;
      system = "aarch64-linux";
      user   = "moisesnessim";
    };

    nixosConfigurations.vm-intel = mkVM "vm-intel" {
      inherit nixpkgs home-manager overlays additionalModules;
      system = "x86_64-linux";
      user   = "moisesnessim";
    };

    darwinConfigurations.macbook-pro-m1 = mkDarwin "macbook-pro-m1" {
      inherit darwin nixpkgs home-manager overlays additionalModules;
      system = "aarch64-darwin";
      user   = "moisesnessim";
    };
  };
}
