{
  lib,
  pkgs,
  nixvim,
  ...
}:
{
  imports = [
    ./plugins/which-key.nix
    ./plugins/nvim-cmp.nix
    ./plugins/alpha.nix
  ];

  programs.nixvim = {
    enable = true;

    defaultEditor = lib.mkForce true;
    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = " ";
    };

    colorschemes.gruvbox.enable = true;

    clipboard = {
      register = "unnamedplus";
      # providers.xclip.enable = true;
    };

    plugins = {
      lazygit.enable = true;
      lualine.enable = true;
      telescope.enable = true;
      lspconfig.enable = true;
      web-devicons.enable = true;
      mini-icons.enable = true;
      auto-session.enable = true;
      toggleterm.enable = true;
      bufferline.enable = true;
      nvim-autopairs.enable = true;
      neo-tree.enable = true;
      oil.enable = true;
      flash.enable = true;
      tiny-inline-diagnostic = {
        enable = true;

        settings = {
          multilines = {
            enabled = true;
          };
          options = {
            use_icons_from_diagnostic = true;
          };
          preset = "classic";

          virt_texts = {
            priority = 2048;
          };

        };

      };
      treesitter = {
        enable = true;

        grammarPackages = pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars;

        settings = {
          indent.enable = true;
          highlight.enable = true;
        };
      };

      image = {
        enable = true;
      };

      molten = {
        enable = true;

        # Configuration settings for molten.nvim. More examples at https://github.com/nix-community/nixvim/blob/main/plugins/by-name/molten/default.nix#L191
        settings = {
          auto_image_popup = false;
          auto_init_behavior = "init";
          auto_open_html_in_browser = false;
          auto_open_output = true;
          cover_empty_lines = false;
          copy_output = false;
          enter_output_behavior = "open_then_enter";
          image_provider = "none";
          output_crop_border = true;
          output_virt_lines = false;
          output_win_border = [
            ""
            "━"
            ""
            ""
          ];
          output_win_hide_on_leave = true;
          output_win_max_height = 15;
          output_win_max_width = 80;
          save_path.__raw = "vim.fn.stdpath('data')..'/molten'";
          tick_rate = 500;
          use_border_highlights = false;
          limit_output_chars = 10000;
          wrap_output = false;
        };
      };
    };

    extraPackages = with pkgs; [
      wl-clipboard
      ripgrep
      # mcpHubCli
    ];

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "takovata";
        src = ./misc;
      })

      (pkgs.vimUtils.buildVimPlugin {
        name = "nim.vim";
        src = pkgs.fetchFromGitHub {
          owner = "zah";
          repo = "nim.vim";
          rev = "a15714fea392b0f06ff2b282921a68c7033e39a2";
          hash = "sha256-ZIDvVto6c9PXtE8O0vp1fL6fuDJrUrYZ0zIXtJBTw+0=";
        };
      })

      (pkgs.vimUtils.buildVimPlugin {
        name = "cargora.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "SersemPeca";
          repo = "cargora.nvim";
          rev = "1c580d261dea151cb385492f926af604685d32ab";
          hash = "sha256-HZqx2kvaESRriN/bdsuGwKxefDvm3NQGoXd/th0haz4=";
        };
      })

      pkgs.vimPlugins.knap

      (pkgs.vimUtils.buildVimPlugin {
        name = "cinnamon.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "declancm";
          repo = "cinnamon.nvim";
          rev = "450cb3247765fed7871b41ef4ce5fa492d834215";
          hash = "sha256-kccQ4iFMSQ8kvE7hYz90hBrsDLo7VohFj/6lEZZiAO8=";
        };
      })

    ];

    lsp = {
      servers = {
        nil_ls.enable = true;
        rust_analyzer.enable = true;
        gopls.enable = true;
        # ccls.enable = true;
        clangd.enable = true;
        nimls.enable = true;
        lua_ls.enable = true;
        ts_ls.enable = true;
        pyright.enable = true;
        csharp_ls.enable = true;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>bd";
        action = ":bdelete<CR>";
        options.silent = true;
      }

      {
        mode = "n";
        key = "<leader>bn";
        action = ":enew<CR>";
        options.silent = true;
      }

      {
        mode = "n";
        key = "<leader>tt";
        action = ":Telescope<CR>";
        options.silent = true;
      }

      {
        mode = "n";
        key = "<leader>n";
        action = ":Neotree<CR>";
        options.silent = true;
      }

      {
        mode = "n";
        key = "gd";
        action.__raw = "vim.lsp.buf.definition";
      }

      {
        mode = "n";
        key = "gr";
        action.__raw = "vim.lsp.buf.references";
      }

      {
        mode = "n";
        key = "gi";
        action.__raw = "vim.lsp.buf.implementation";
      }

      {
        mode = "n";
        key = "K";
        action.__raw = "vim.lsp.buf.hover";
      }

      {
        mode = "n";
        key = "<leader>la";
        action.__raw = "vim.lsp.buf.code_action";
      }

      {
        mode = "n";
        key = "<leader>lr";
        action.__raw = "vim.lsp.buf.rename";
      }

      {
        mode = "n";
        key = "[d";
        action.__raw = "vim.diagnostic.goto_prev";
      }

      {
        mode = "n";
        key = "]d";
        action.__raw = "vim.diagnostic.goto_next";
      }

      {
        mode = "t";
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
      }

      {
        mode = "n";
        key = "<leader>/";
        action = ":ToggleTerm<CR>";
      }

      {
        mode = "n";
        key = "zk";
        action = "<cmd>lua require('flash').jump()<CR>";
      }

      {
        mode = "x";
        key = "<leader>re";
        action = ":Refactor extract<CR>";
        options = {
          silent = true;
          noremap = true;
        };
      }
    ];

    opts = {
      number = true;
      relativenumber = true;
      # autoindent = true;
      # smartindent = true;

      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      expandtab = true;
    };

    extraConfigLua = builtins.readFile ./lua/config.lua;
  };
}
