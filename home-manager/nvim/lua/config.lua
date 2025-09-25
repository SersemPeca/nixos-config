require("mcphub").setup()

-- Autoformat on save using LSP
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
