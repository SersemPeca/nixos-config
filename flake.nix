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

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
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
      nixos-hardware,
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
            nixvim.overlays.default
            (self: super: {
              codex = super.callPackage ./packages/codex-cli/default.nix { };
            })
          ];

          mkHM =
            system: user:
            hmLib.homeManagerConfiguration {

              inherit pkgs;

              extraSpecialArgs = {
                inherit nixvim mcp-hub mcp-hub-nvim;
                hostName = "default";
              };

              modules = [
                ./home-manager/home.nix
                nixvim.homeModules.nixvim

                {
                  home.username = user;
                  home.homeDirectory = "/home/${user}";
                }
              ];
            };

        in
        {

          packages.${system}.codex = pkgs.codex;

          nixosConfigurations = {
            nixos-lenovo = nixpkgs.lib.nixosSystem {
              inherit system pkgs;

              modules = [
                home-manager.nixosModules.home-manager

                ./hosts/lenovo/configuration.nix
                ./hosts/lenovo/hardware-configuration.nix

                nixos-hardware.nixosModules.lenovo-thinkpad-x1-12th-gen

                (
                  { ... }:
                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      useUserPackages = true;
                      backupFileExtension = "backup";

                      extraSpecialArgs = {
                        inherit nixvim mcp-hub mcp-hub-nvim;
                        hostName = "lenovo";
                      };

                      users.petara = {
                        imports = [
                          nixvim.homeModules.nixvim
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

            nixos-gpd = nixpkgs.lib.nixosSystem {
              inherit system pkgs;

              modules = [
                home-manager.nixosModules.home-manager

                ./hosts/gpd/configuration.nix
                ./hosts/gpd/hardware-configuration.nix

                nixos-hardware.nixosModules.gpd-pocket-4

                (
                  { ... }:
                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      useUserPackages = true;
                      backupFileExtension = "backup";

                      extraSpecialArgs = {
                        inherit nixvim mcp-hub mcp-hub-nvim;
                        hostName = "gpd-pocket-4";
                      };

                      users.petara = {
                        imports = [
                          nixvim.homeModules.nixvim
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

            nixos-framework-mini = nixpkgs.lib.nixosSystem {
              inherit system pkgs;

              modules = [
                home-manager.nixosModules.home-manager
                ./hosts/framework-mini/configuration.nix
                ./hosts/framework-mini/hardware-configuration.nix

                nixos-hardware.nixosModules.framework-amd-ai-300-series

                (
                  { ... }:
                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      useUserPackages = true;
                      backupFileExtension = "backup";

                      extraSpecialArgs = {
                        # inherit mcp-hub mcp-hub-nvim;
                        inherit nixvim;
                        hostName = "framework-mini";
                      };

                      users.petara = {
                        imports = [
                          nixvim.homeModules.nixvim
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
            nixos-framework = nixpkgs.lib.nixosSystem {
              inherit system pkgs;

              modules = [
                home-manager.nixosModules.home-manager
                ./hosts/framework/configuration.nix
                ./hosts/famework/hardware-configuration.nix

                (
                  { ... }:
                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      useUserPackages = true;
                      backupFileExtension = "backup";

                      extraSpecialArgs = {
                        inherit nixvim mcp-hub mcp-hub-nvim;
                        hostName = "framework";
                      };

                      users.petara = {
                        imports = [
                          nixvim.homeModules.nixvim
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
          };

          homeConfigurations = {
            # petara = mkHM system "petara";
            pesho = mkHM system "pesho";
          };
        };
    };
}
