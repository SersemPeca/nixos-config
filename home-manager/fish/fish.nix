{
  lib,
  config,
  ...
}:
{

  options = {
    custom.fish.enable = lib.mkEnableOption "fish";
  };

  config = {
    programs.fish = lib.mkIf config.custom.fish.enable {
      enable = true;
    };
  };
}
