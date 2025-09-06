{
  pkgs,
  lib,
  ...
}:

{

  imports = [
    ./nvim/nvim.nix
    ./wezterm/wezterm.nix
    ./waybar/waybar.nix
    ./hyprland/hyprland.nix
    ./dunst/dunst.nix
    ./fish/fish.nix
  ];

  custom = {
    hyprland.enable = false;
    waybar.enable = false;
    dunst.enable = false;
    fish.enable = false;
    wezterm.enable = false;
  };

  home.stateVersion = "24.11";

  home.sessionVariables = lib.mkForce {
    EDITOR = "nvim";
  };

  home.shell.enableFishIntegration = true;

  fonts.fontconfig.enable = true;

  home.packages = [
    # home-manager

    pkgs.nerd-fonts.fira-code
  ];

  programs.home-manager.enable = true;

  programs.wofi = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
  };

  programs.firefox = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "SersemPeca";
    userEmail = "p.atanasov21@abv.bg";
  };

}
