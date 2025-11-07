{
  config,
  lib,
  hostName,
  ...
}:
{

  options = {
    custom.hyprland.enable = lib.mkEnableOption "hyprland";
  };

  config = {

    wayland.windowManager.hyprland = lib.mkIf config.custom.hyprland.enable {
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

        monitor = lib.mkIf (hostName == "gpd-pocket-4") [
          "eDP-1, preferred, auto, 1, transform, 3"
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

          # Move focused window to workspace (don’t follow)
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"

          # Brightness
          ",XF86MonBrightnessUp,   exec, brightnessctl -d amdgpu_bl1 set +5%"
          ",XF86MonBrightnessDown, exec, brightnessctl -d amdgpu_bl1 set 5%-A"

          # Volume
          ",XF86AudioRaiseVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ];
      };
    };
  };
}
