{
  pkgs,
  lib,
  nixvim,
  ...
}:

{

  imports = [
    (import ./nvim/nvim.nix {
      inherit
        pkgs
        lib
        nixvim
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

  home = {

    stateVersion = "24.11";
    sessionVariables = lib.mkForce {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
    };

    shell.enableFishIntegration = true;

    packages = with pkgs; [
      # home-manager

      nerd-fonts.fira-code

      (callPackage ../packages/codex-cli/default.nix { })

      signal-desktop

      brightnessctl

      xfce.thunar
      xfce.thunar-archive-plugin
      xfce.thunar-volman
      xfce.tumbler
      xfce.exo

      python313Packages.jupyterlab
      python3Packages.ipykernel
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
      enableDefaultConfig = false;
      matchBlocks."*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
    };

    firefox = {
      enable = true;
    };

    git = {
      enable = true;
      settings.user = {
        name = "SersemPeca";
        email = "p.atanasov21@abv.bg";
      };
    };

    btop = {
      enable = true;
    };

    zed-editor = {
      enable = true;
    };

    vscode = {
      enable = true;
    };

  };

}
