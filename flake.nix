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
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };

    mcp-hub = {
      url = "github:ravitemer/mcp-hub";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mcp-hub-nvim = {
      url = "github:ravitemer/mcphub.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    pi-flake = {
      url = "github:ChauDucToan/pi-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem =
        {
          system,
          pkgs,
          ...
        }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              inputs.nixvim.overlays.default
              (final: prev: {
                codex = prev.callPackage ./packages/codex-cli/default.nix { };
              })
              (final: prev: {
                pi = prev.callPackage ./packages/pi-coding-agent/default.nix { };
              })
            ];
            config = {
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
          };

          packages.codex = pkgs.codex;
        };

      flake =
        let
          inherit (inputs)
            home-manager
            nixvim
            hyprland
            mcp-hub
            mcp-hub-nvim
            nixos-hardware
            ;

          # Common module for all NixOS configurations
          commonNixosModule = {
            nixpkgs.overlays = [
              nixvim.overlays.default
              (final: prev: {
                codex = prev.callPackage ./packages/codex-cli/default.nix { };
              })
              (final: prev: {
                pi = prev.callPackage ./packages/pi-coding-agent/default.nix { };
              })
            ];
            nixpkgs.config = {
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit
                  inputs
                  nixvim
                  hyprland
                  mcp-hub
                  mcp-hub-nvim
                  ;
              };
            };
          };

          # Helper to create NixOS system configurations
          mkNixosSystem =
            {
              hostPath,
              hardwareModules ? [ ],
            }:
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                home-manager.nixosModules.home-manager
                commonNixosModule
                (hostPath + "/configuration.nix")
                (hostPath + "/hardware-configuration.nix")
                (hostPath + "/home-manager.nix")
              ]
              ++ hardwareModules;
              specialArgs = {
                inherit inputs nixvim hyprland;
              };
            };

          # Helper to create home-manager configurations
          mkHome =
            {
              username,
              hostName ? "default",
              extraModules ? [ ],
            }:
            home-manager.lib.homeManagerConfiguration {
              pkgs = self.legacyPackages.x86_64-linux;
              extraSpecialArgs = {
                inherit
                  inputs
                  nixvim
                  mcp-hub
                  mcp-hub-nvim
                  hostName
                  ;
              };
              modules = [
                ./home-manager/home.nix
                nixvim.homeModules.nixvim
                {
                  home = {
                    inherit username;
                    homeDirectory = "/home/${username}";
                  };
                }
              ]
              ++ extraModules;
            };
        in
        {
          nixosConfigurations = {
            nixos-lenovo = mkNixosSystem {
              hostPath = ./hosts/lenovo;
              hardwareModules = [ nixos-hardware.nixosModules.lenovo-thinkpad-x1-12th-gen ];
            };

            nixos-gpd = mkNixosSystem {
              hostPath = ./hosts/gpd;
              hardwareModules = [ nixos-hardware.nixosModules.gpd-pocket-4 ];
            };

            nixos-desktop = mkNixosSystem {
              hostPath = ./hosts/desktop;
            };

            nixos-framework-mini = mkNixosSystem {
              hostPath = ./hosts/framework-mini;
              hardwareModules = [ nixos-hardware.nixosModules.framework-amd-ai-300-series ];
            };

            nixos-framework = mkNixosSystem {
              hostPath = ./hosts/framework;
            };
          };

          homeConfigurations = {
            pesho = mkHome { username = "pesho"; };

            thinkpad-e15 = mkHome {
              username = "petara";
              hostName = "thinkpad-e15";
              extraModules = [
                ./hosts/home-common.nix
                ./hosts/thinkpad-e15/home-manager.nix
              ];
            };
          };
        };
    };
}
