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

    mcp-hub = {
      url = "github:ravitemer/mcp-hub";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = true;
    };

    mcp-hub-nvim = {
      url = "github:ravitemer/mcphub.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = true;
    };

  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      home-manager,
      nixvim,
      hyprland,
      mcp-hub,
      mcp-hub-nvim,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [ "x86_64-linux" ];

      perSystem =
        { system, pkgs, ... }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        };

      flake =
        let
          mkPkgs =
            system: overlays:
            import nixpkgs {
              inherit system overlays;
              config.allowUnfree = true;
            };

          hmLib = home-manager.lib;

          mcp-hub-nvim = inputs.mcp-hub-nvim.packages."${system}".default;

          system = "x86_64-linux";

          pkgs = mkPkgs system [
            (self: super: {
              codex = super.callPackage ./packages/codex-cli/default.nix { };
            })
          ];

          mkHM =
            system: user:
            hmLib.homeManagerConfiguration {

              inherit pkgs;

              extraSpecialArgs = {
                inherit mcp-hub mcp-hub-nvim;
              };

              modules = [
                ./home-manager/home.nix
                nixvim.homeManagerModules.nixvim

                {
                  home.username = user;
                  home.homeDirectory = "/home/${user}";
                }
              ];
            };

        in
        {

          packages.${system}.codex = pkgs.codex;

          nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
            inherit system pkgs;

            modules = [
              home-manager.nixosModules.home-manager
              ./configuration.nix
              ./hardware-configuration.nix

              (
                { ... }:
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;

                    extraSpecialArgs = {
                      inherit mcp-hub mcp-hub-nvim;
                    };

                    users.petara = {
                      imports = [
                        nixvim.homeManagerModules.nixvim
                        ./home-manager/home.nix
                      ];
                    };
                  };
                }
              )
            ];

            specialArgs = {
              inherit nixvim hyprland;
            };
          };

          homeConfigurations = {
            # petara = mkHM system "petara";
            pesho = mkHM system "pesho";
          };
        };
    };
}
