{
  pkgs,
  nixvim,
  hyprland,
  ...
}:

{

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  # nixpkgs.config.allowUnfree = true;

  # Hardware.
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;
  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us,bg";
      variant = ",phonetic";
      options = "grp:alt_space_toggle";
    };

  };

  # Display manager configuration
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${hyprland.packages."${pkgs.stdenv.hostPlatform.system}".hyprland}/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # TTY configuration for greetd (fixes bootlog spam)
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # Make sure greetd sessions directory exists
  systemd.tmpfiles.rules = [
    "d '/var/cache/tuigreet' - greeter greeter - -"
  ];

  services.upower.enable = true;

  services.seatd.enable = true;

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 5d";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    wezterm
    bluez
    usbutils

    # Screen snapshotting utils
    grim
    slurp
    wl-clipboard
  ];

  programs.hyprland = {
    enable = true;
    package = hyprland.packages."${pkgs.stdenv.hostPlatform.system}".hyprland;
    portalPackage = hyprland.packages."${pkgs.stdenv.hostPlatform.system}".xdg-desktop-portal-hyprland;
  };

  # Ensure XDG portals are enabled
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

}
