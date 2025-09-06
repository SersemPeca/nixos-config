{
  description = "NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
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
    {
      nixpkgs,
      home-manager,
      nixvim,
      hyprland,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        allowUnfree = true;
      };

      hm = home-manager.lib;

      generateHomeManagerConfig =
        user:
        hm.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home-manager/home.nix
            nixvim.homeManagerModules.nixvim # provides `programs.nixvim.*`

            {
              home.username = user;
              home.homeDirectory = "/home/${user}";
            }

          ];

          extraSpecialArgs = { inherit nixvim; };
        };
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system pkgs;
          modules = [
            home-manager.nixosModules.home-manager

            ./configuration.nix
            ./hardware-configuration.nix
          ];

          specialArgs = { inherit nixvim hyprland; };

        };

      };

      homeConfigurations.petara = generateHomeManagerConfig "petara";

      homeConfigurations.pesho = generateHomeManagerConfig "pesho";

    };
}
