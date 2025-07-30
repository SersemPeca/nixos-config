{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {

      "$mod" = "SUPER";

      input = {
        repeat_delay = 200;
        repeat_rate = 45;
      };

      exec-once = [
        "waybar"
      ];

      bind = [
        "$mod, RETURN, exec, wezterm"
        "$mod, SPACE, exec, wofi --show drun"
        "$mod, Q, killactive"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
      ];
    };
  };
}
