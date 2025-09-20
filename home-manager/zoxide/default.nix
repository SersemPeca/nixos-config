{
  lib,
  config,
  ...
}:
{

  options = {
    custom.zoxide.enable = lib.mkEnableOption "fish";
  };

  config = {
    programs.zoxide = lib.mkIf config.custom.zoxide.enable {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
