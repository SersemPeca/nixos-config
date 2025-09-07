{
  description = "NixOS config (flake-parts)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      home-manager,
      nixvim,
      hyprland,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [ "x86_64-linux" ];

      perSystem =
        { system, ... }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          # packages.default = pkgs.hello;
          # devShells.default = pkgs.mkShell { buildInputs = [ pkgs.git ]; };
        };

      flake =
        let
          mkPkgs =
            system:
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };

          hmLib = home-manager.lib;

          mkHM =
            system: user:
            hmLib.homeManagerConfiguration {
              pkgs = mkPkgs system;
              modules = [
                ./home-manager/home.nix
                nixvim.homeManagerModules.nixvim
                {
                  home.username = user;
                  home.homeDirectory = "/home/${user}";
                }
              ];
              extraSpecialArgs = { inherit nixvim; };
            };

          system = "x86_64-linux";
        in
        {
          nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
            inherit system;
            pkgs = mkPkgs system;

            modules = [
              home-manager.nixosModules.home-manager
              ./configuration.nix
              ./hardware-configuration.nix
            ];

            specialArgs = {
              inherit nixvim hyprland;
            };
          };

          homeConfigurations = {
            petara = mkHM system "petara";
            pesho = mkHM system "pesho";
          };
        };
    };
}
