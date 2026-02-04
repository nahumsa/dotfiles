return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "jinja",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "go",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
        "sql",
      },
    },
  },
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
    config = true,
  },
}
