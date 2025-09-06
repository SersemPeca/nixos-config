{
  pkgs,
  lib,
  config,
  ...
}:
{

  options = {
    custom.fish.enable = lib.mkEnableOption "fish";
  };

  config = {
    programs.fish = {
      enable = true;
    };
  };
}
