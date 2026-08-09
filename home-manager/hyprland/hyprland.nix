{
  config,
  lib,
  pkgs,
  hostName ? "default",
  hyprland,
  ...
}:
let
  lua = lib.generators.mkLuaInline;

  dsp = {
    exec = cmd: lua ''hl.dsp.exec_cmd("${cmd}")'';
    close = lua "hl.dsp.window.close()";
    exit = lua "hl.dsp.exit()";
    float = lua ''hl.dsp.window.float({ action = "toggle" })'';
    fullscreen = lua "hl.dsp.window.fullscreen()";
    pseudo = lua "hl.dsp.window.pseudo()";
    layout = msg: lua ''hl.dsp.layout("${msg}")'';
    focus = dir: lua ''hl.dsp.focus({ direction = "${dir}" })'';
    swap = dir: lua ''hl.dsp.window.swap({ direction = "${dir}" })'';
    workspace = id: lua ''hl.dsp.focus({ workspace = ${toString id} })'';
    moveToWorkspace = id: lua ''hl.dsp.window.move({ workspace = ${toString id} })'';
  };

  bind = keys: dispatcher: { _args = [keys dispatcher]; };
  bindOpts = keys: dispatcher: opts: { _args = [keys dispatcher opts]; };

  workspaceBinds = lib.concatMap (i:
    let key = toString (lib.mod i 10);
    in [
      (bind "SUPER + ${key}" (dsp.workspace i))
      (bind "SUPER + SHIFT + ${key}" (dsp.moveToWorkspace i))
    ]
  ) (lib.range 1 10);
in
{

  options = {
    custom.hyprland.enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf config.custom.hyprland.enable {

    wayland.windowManager.hyprland = {
      enable = true;
      package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      configType = "lua";

      settings = {
        monitor = [{
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "auto";
        }];

        config = {
          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            col = {
              active_border = "rgba(33ccffee)";
              inactive_border = "rgba(595959aa)";
            };
            layout = "dwindle";
          };

          decoration = {
            rounding = 10;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };
          };

          animations = {
            enabled = true;
          };

          dwindle = {
            preserve_split = true;
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
          };

          input = {
            kb_layout = "us,bg";
            kb_variant = ",phonetic";
            kb_options = "grp:alt_space_toggle";
            repeat_delay = 200;
            repeat_rate = 45;
            follow_mouse = 1;
            sensitivity = 0;
            touchpad = {
              natural_scroll = false;
            };
          };
        };

        curve = [{
          _args = [
            "myBezier"
            {
              type = "bezier";
              points = lua "{ {0.05, 0.9}, {0.1, 1.05} }";
            }
          ];
        }];

        animation = [
          { leaf = "windows"; enabled = true; speed = 7; bezier = "myBezier"; }
          { leaf = "windowsOut"; enabled = true; speed = 7; bezier = "default"; style = "popin 80%"; }
          { leaf = "border"; enabled = true; speed = 10; bezier = "default"; }
          { leaf = "borderangle"; enabled = true; speed = 8; bezier = "default"; }
          { leaf = "fade"; enabled = true; speed = 7; bezier = "default"; }
          { leaf = "workspaces"; enabled = true; speed = 6; bezier = "default"; }
        ];

        on = {
          _args = [
            "hyprland.start"
            (lua ''
              function()
                hl.exec_cmd("waybar &")
              end'')
          ];
        };

        bind = [
          # App launchers
          (bind "SUPER + RETURN" (dsp.exec "ghostty"))
          (bind "SUPER + Q" dsp.close)
          (bind "SUPER + SPACE" (dsp.exec "wofi --show drun"))
          (bind "SUPER + L" (dsp.exec "hyprlock"))
          (bind "SUPER + S" (lua "hl.dsp.exec_cmd([[bash -lc 'grim -g \"$(slurp)\" - | swappy -f -']])"))

          # Media keys
          (bindOpts "XF86MonBrightnessUp" (dsp.exec "brightnessctl -d amdgpu_bl1 set +5%") { locked = true; })
          (bindOpts "XF86MonBrightnessDown" (dsp.exec "brightnessctl -d amdgpu_bl1 set 5%-") { locked = true; })
          (bindOpts "XF86AudioRaiseVolume" (dsp.exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") { locked = true; })
          (bindOpts "XF86AudioLowerVolume" (dsp.exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") { locked = true; })
          (bindOpts "XF86AudioMute" (dsp.exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") { locked = true; })
        ] ++ workspaceBinds;
      };
    };

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "hyprlock";
          before_sleep_cmd = "hyprlock";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 1800;
            on-timeout = "hyprlock";
          }
        ];
      };
    };

    programs.hyprlock.enable = true;
  };
}
