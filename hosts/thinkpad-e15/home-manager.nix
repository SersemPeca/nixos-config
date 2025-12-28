{ lib, ... }:
{
  custom = {
    hyprland.enable = lib.mkForce false;
    waybar.enable = lib.mkForce false;
    dunst.enable = lib.mkForce false;
    fish.enable = lib.mkForce false;
    wezterm.enable = lib.mkForce false;
    zoxide.enable = lib.mkForce false;
  };
}
