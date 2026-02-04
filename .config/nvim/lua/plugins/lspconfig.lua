return {
  "neovim/nvim-lspconfig",
  -- 'init' runs on startup, making sure filetypes are registered early
  init = function()
    vim.filetype.add({
      extension = {
        jinja = "jinja",
        jinja2 = "jinja",
        j2 = "jinja",
        py = "python",
      },
    })
  end,
  ---@class PluginLspOpts
  opts = {
    ---@type lspconfig.options
    servers = {
      pyright = {},
      jinja_lsp = {
        filetypes = { "jinja", "rust", "python", "sql" },
      },
    },
  },
}
