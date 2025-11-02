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
  };

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
    layout = "us";
    xkb = {
      layout = "us";
      variant = "";
    };
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
  };

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
    package = hyprland.packages."${pkgs.system}".hyprland;
    # withUWSM = true;
  };

}
