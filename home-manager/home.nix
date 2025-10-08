{
  pkgs,
  lib,
  mcp-hub,
  mcp-hub-nvim,
  ...
}:

{

  imports = [
    (import ./nvim/nvim.nix {
      inherit
        pkgs
        lib
        mcp-hub
        mcp-hub-nvim
        ;
    })
    # ./nvim/nvim.nix
    ./wezterm/wezterm.nix
    ./waybar/waybar.nix
    ./hyprland/hyprland.nix
    ./dunst/dunst.nix
    ./fish/fish.nix
    ./zoxide
  ];

  # custom = {
  #   hyprland.enable = false;
  #   waybar.enable = false;
  #   dunst.enable = false;
  #   fish.enable = false;
  #   wezterm.enable = false;
  # };

  custom = {
    hyprland.enable = true;
    waybar.enable = true;
    dunst.enable = true;
    fish.enable = true;
    wezterm.enable = true;
    zoxide.enable = true;
  };

  home = {

    stateVersion = "24.11";
    sessionVariables = lib.mkForce {
      EDITOR = "nvim";
    };

    shell.enableFishIntegration = true;

    packages = [
      # home-manager

      pkgs.nerd-fonts.fira-code
    ];

  };

  fonts.fontconfig.enable = true;

  programs = {

    home-manager.enable = true;

    wofi = {
      enable = true;
    };

    ssh = {
      enable = true;
    };

    firefox = {
      enable = true;
    };

    git = {
      enable = true;
      userName = "SersemPeca";
      userEmail = "p.atanasov21@abv.bg";
    };

    btop = {
      enable = true;
    };
  };

}
