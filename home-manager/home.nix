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

    pointerCursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    packages =
      with pkgs;
      [
        # home-manager

        (callPackage ../packages/codex-cli/default.nix { })

        signal-desktop

        kdePackages.okular

        brightnessctl

        xfce.thunar
        xfce.thunar-archive-plugin
        xfce.thunar-volman
        xfce.tumbler
        xfce4-exo

        python313Packages.jupyterlab
        python3Packages.ipykernel

        zip
        unzip

        tig
      ]
      ++ (lib.filter lib.isDerivation (lib.attrValues pkgs."nerd-fonts"));

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

    vscode = {
      enable = true;
    };

    hyprlock = {
      enable = true;
    };

    zellij = {
      enable = true;
    };

  };

}
