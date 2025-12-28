{ lib, ... }:
{
  custom = {
    hyprland.enable = lib.mkDefault true;
    waybar.enable = lib.mkDefault true;
    dunst.enable = lib.mkDefault true;
    fish.enable = lib.mkDefault true;
    wezterm.enable = lib.mkDefault true;
    zoxide.enable = lib.mkDefault true;
  };
}
