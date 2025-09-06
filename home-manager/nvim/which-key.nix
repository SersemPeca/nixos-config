_:

{
  programs.nixvim.plugins.which-key = {
    enable = true;

    settings.spec = [
      {
        __unkeyed-1 = "<leader>l";
        mode = "n";
        group = "LSP";
      }
      {
        __unkeyed-1 = "<leader>t";
        mode = "n";
        group = "Tabs";
      }
      {
        __unkeyed-1 = "<leader>tc";
        mode = "n";
        group = "Close";
      }
      {
        __unkeyed-1 = "<leader>tn";
        mode = "n";
        group = "New";
      }
      {
        __unkeyed-1 = "<leader>tt";
        mode = "n";
        group = "Telescope";
      }
    ];
  };
}
