{ lib, nixvim, ... }:

{

  programs.nixvim.plugins.startup = {
    enable = true;

    settings = {
      parts = [
        "header"
        "body"
        "footer"
      ];

      header = {
        type = "text";
        align = "center";
        fold_section = false;
        title = "Header";
        margin = 5;
        highlight = "Type";
        default_color = "";
        oldfiles_directory = false;
        oldfiles_amount = 0;
        content = [
          "███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
          "████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
          "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
          "██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
          "██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
          "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
        ];
      };

      body = {
        type = "mapping";
        align = "center";
        fold_section = false;
        title = "Actions";
        margin = 5;
        highlight = "String";
        default_color = "";
        oldfiles_directory = false;
        oldfiles_amount = 0;
        content = [
          [
            "  New file"
            "enew"
            "n"
          ]
          [
            "  Quit Neovim"
            "qa"
            "q"
          ]
        ];
      };

      footer = {
        type = "text";
        align = "center";
        fold_section = false;
        title = "Footer";
        margin = 5;
        highlight = "Keyword";
        default_color = "";
        oldfiles_directory = false;
        oldfiles_amount = 0;
        content = nixvim.lib.nixvim.mkRaw "require('startup.functions').quote";
      };

      options = {
        mapping_keys = true;
        cursor_column = 0.5;
        empty_lines_between_mappings = true;
        disable_statuslines = true;
        paddings = [
          1
          3
          3
          0
        ];
      };

      mappings = {
        execute_command = "<CR>";
        open_file = "o";
        open_file_split = "<c-o>";
        open_section = "<TAB>";
        open_help = "?";
      };

      colors = {
        background = "#1f2227";
        folded_section = "#56b6c2";
      };
    };
  };

}
