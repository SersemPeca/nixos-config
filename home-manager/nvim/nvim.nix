{
  config,
  lib,
  pkgs,
  ...
}:
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
      providers.xclip.enable = true;
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
    };

    lsp = {
      servers = {
        nil_ls.enable = true;
        rust_analyzer.enable = true;
        gopls.enable = true;
        ccls.enable = true;
        nimls.enable = true;
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

    extraConfigLua = ''

      -- Autoformat on save using LSP
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function()
          vim.lsp.buf.format({ async = false })
        end,
      })

    '';
  };
}
