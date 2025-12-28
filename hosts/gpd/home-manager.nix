{
  nixvim,
  mcp-hub,
  mcp-hub-nvim,
  ...
}:
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
        ./../home-common.nix
        ./../../home-manager/home.nix
      ];
    };
  };
}
