{
  config,
  pkgs,
  lib,
  nixvim,
  ...
}:

{
  home.stateVersion = "24.11";

  imports = [
    ./nvim/nvim.nix
    ./wezterm/wezterm.nix
    ./waybar/waybar.nix
    ./hyprland/hyprland.nix
  ];

  home.sessionVariables = lib.mkForce {
    EDITOR = "nvim";
  };

  home.shell.enableFishIntegration = true;

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    home-manager

    pkgs.nerd-fonts.fira-code
  ];

  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
  };

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

  services.dunst = {
    enable = true;
  };

}
