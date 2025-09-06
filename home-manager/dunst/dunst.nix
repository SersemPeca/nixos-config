{
  lib,
  config,
  ...
}:
{

  options = {
    custom.dunst.enable = lib.mkEnableOption "dunst";
  };

  config = {

    services.dunst = lib.mkIf config.custom.dunst.enable {
      enable = true;
    };

  };
}
