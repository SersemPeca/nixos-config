{ pkgs }:
{

  programs.nixvim.plugins.treesitter = {
    enable = true;

    grammarPackages = pkgs.vimPlugins.nvim-treesitter.passthru.allGrammars;

    settings = {
      indent.enable = true;
      highlight.enable = true;
    };
  };
}
