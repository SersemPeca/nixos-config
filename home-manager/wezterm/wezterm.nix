{ config, pkgs, ... }:

let
  walDir = "${config.xdg.cacheHome}/wal";
  fishBin = "${pkgs.fish}/bin/fish";
in
{
  programs.wezterm = {
    enable = true;

    # Optional: use a custom wezterm package
    # package = pkgs.wezterm;

    # You may define custom color schemes if not using 'wezterm-wal'
    # colorSchemes = {
    #   "CustomScheme" = {
    #     foreground = "#ffffff";
    #     background = "#000000";
    #     ansi = [ "#000000" "#ff0000" "#00ff00" "#ffff00" "#0000ff" "#ff00ff" "#00ffff" "#ffffff" ];
    #     brights = [ "#555555" "#ff5555" "#55ff55" "#ffff55" "#5555ff" "#ff55ff" "#55ffff" "#ffffff" ];
    #   };
    # };

    extraConfig = ''
      local wezterm = require("wezterm")

      -- Watch config dir and wal cache dir for reloads
      wezterm.add_to_config_reload_watch_list(wezterm.config_dir)
      wezterm.add_to_config_reload_watch_list("${walDir}")

      return {
        -------------
        -- Font
        -------------
        font = wezterm.font("FiraCode Nerd Font Mono"),
        harfbuzz_features = {
          "liga",
          "cv02", "cv19", "cv25", "cv26", "cv28", "cv30", "cv32",
          "ss02", "ss03", "ss05", "ss07", "ss09", "zero",
        },
        freetype_render_target = "Light",

        -------------
        -- Window
        -------------
        window_decorations = "NONE",
        window_close_confirmation = "NeverPrompt",
        use_resize_increments = false,
        enable_scroll_bar = false,
        adjust_window_size_when_changing_font_size = false,
        window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
        default_prog = { "${fishBin}" },

        -------------
        -- Tab Bar
        -------------
        enable_tab_bar = false,

        -------------
        -- Key Bindings
        -------------
        disable_default_key_bindings = true,
        keys = {
          { mods = "ALT", key = "c", action = wezterm.action.CopyTo("Clipboard") },
          { mods = "ALT", key = "v", action = wezterm.action.PasteFrom("Clipboard") },
          { mods = "ALT", key = "UpArrow", action = wezterm.action.IncreaseFontSize },
          { mods = "ALT", key = "DownArrow", action = wezterm.action.DecreaseFontSize },
          { mods = "ALT", key = "u", action = wezterm.action.ScrollByPage(-1) },
          { mods = "ALT", key = "d", action = wezterm.action.ScrollByPage(1) },
          { mods = "CTRL|SHIFT", key = "r", action = wezterm.action.ReloadConfiguration },
        },

        -------------
        -- Color Scheme
        -------------
        color_scheme = "wezterm-wal",  -- must exist or be provided externally
        color_scheme_dirs = { "${walDir}" },

        -------------
        -- Hyperlink Rules
        -------------
        hyperlink_rules = {
          {
            regex = [[\b\w+://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&/=]*)]],
            format = "$0",
          },
          {
            regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
            format = "mailto:$0",
          },
          {
            regex = [[\bfile://\S*\b]],
            format = "$0",
          },
        },
      }
    '';
  };
}
