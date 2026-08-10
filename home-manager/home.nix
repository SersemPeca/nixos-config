{
  pkgs,
  lib,
  inputs,
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
    ./zoxide
    inputs.pi-flake.homeManagerModules.default
  ];

  programs.pi-coding-agent = {
    enable = true;
  };

  home = {

    stateVersion = "24.11";
    sessionVariables = lib.mkForce {
      EDITOR = "nvim";
      NIXOS_OZONE_WL = "1";
    };

    shell.enableFishIntegration = true;

    pointerCursor = {
      enable = true;
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

        # (callPackage ../packages/codex-cli/default.nix { })

        signal-desktop
        viber

        kdePackages.okular

        brightnessctl
        grim
        slurp
        swappy
        wl-clipboard

        thunar
        thunar-archive-plugin
        thunar-volman
        tumbler
        xfce4-exo

        python313Packages.jupyterlab
        python3Packages.ipykernel

        zip
        unzip

        tig
        lazygit

        ripgrep

        claude-code
        claude-monitor
      ]
      ++ (lib.filter lib.isDerivation (lib.attrValues pkgs."nerd-fonts"));

  };

  fonts.fontconfig.enable = true;

  programs = {

    home-manager.enable = true;

    kitty.enable = true;

    wofi = {
      enable = true;
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
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
    };

    firefox = {
      enable = true;
      configPath = ".mozilla/firefox";
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

    ghostty = {
      enable = true;
      settings = {
        shell-integration = "fish";
        command = "fish";
      };
    };

  };

}
