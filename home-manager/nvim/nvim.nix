{
  lib,
  pkgs,
  mcp-hub-nvim,
  mcp-hub,
  ...
}:
let
  mcpHubCli = mcp-hub.packages.${pkgs.system}.default;
in
{
  imports = [
    ./which-key.nix
    ./nvim-cmp.nix
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
      toggleterm.enable = true;
      bufferline.enable = true;
      nvim-autopairs.enable = true;
      neo-tree.enable = true;
      oil.enable = true;
      treesitter = {
        enable = true;

        grammarPackages = pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars;

        settings = {
          indent.enable = true;
          highlight.enable = true;
        };
      };

      # rustaceanvim = {
      #   enable = true;
      # };

      # Agentic coding
      avante = {
        enable = true;
        settings = {
          provider = "openai";
          # auto_suggestions_provider = "copilot";
        };
      };

      refactoring = {
        enable = true;
      };

      # vimtex = {
      #   enable = true;
      # };
    };

    extraPackages = with pkgs; [
      wl-clipboard
      ripgrep
      mcpHubCli
    ];

    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "takovata";
        src = ./banica;
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

      # (pkgs.vimUtils.buildVimPlugin {
      #   name = "knap";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "frabjous";
      #     repo = "knap";
      #     rev = "7db44d0bb760120142cc1e8f43e44976de59c2f6";
      #     hash = "sha256-BX/y1rEcDqj96rDssWwrMbj93SVIfFCW3tFgsFI1d4M=";
      #   };
      # })

      mcp-hub-nvim

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
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>tc";
        action = ":tabclose<CR>";
        options.silent = true;
      }

      {
        mode = "n";
        key = "<leader>tn";
        action = ":tabnew<CR>";
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
        action = "vim.lsp.buf.definition";
        lua = true;
      }

      {
        mode = "n";
        key = "gr";
        action = "vim.lsp.buf.references";
        lua = true;
      }

      {
        mode = "n";
        key = "gi";
        action = "vim.lsp.buf.implementation";
        lua = true;
      }

      {
        mode = "n";
        key = "K";
        action = "vim.lsp.buf.hover";
        lua = true;
      }

      {
        mode = "n";
        key = "<leader>la";
        action = "vim.lsp.buf.code_action";
        lua = true;
      }

      {
        mode = "n";
        key = "<leader>lr";
        action = "vim.lsp.buf.rename";
        lua = true;
      }

      {
        mode = "n";
        key = "[d";
        action = "vim.diagnostic.goto_prev";
        lua = true;
      }

      {
        mode = "n";
        key = "]d";
        action = "vim.diagnostic.goto_next";
        lua = true;
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
