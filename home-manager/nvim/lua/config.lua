require("cinnamon").setup({
  keymaps = { basic = true, extra = true },
  options = {
    delay = 2,                  -- default is 5ms
    max_delta = { time = 250 }, -- default is 1000ms
    step_size = {
      vertical = 2,             -- default is 1
      horizontal = 4,           -- default is 2
    },
  },
})
-- Autoformat on save using LSP
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
