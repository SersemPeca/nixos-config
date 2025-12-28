{ nixvim, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    extraSpecialArgs = {
      inherit nixvim;
      hostName = "framework-mini";
    };

    users.petara = {
      imports = [
        nixvim.homeModules.nixvim
        ./../home-common.nix
        ./../../home-manager/home.nix
      ];
    };
  };
}
