return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
    end,
  },
  { import = "lazyvim.plugins.extras.lang.typescript" },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, "😄")
    end,
  },
  {
    "xiyaowong/transparent.nvim",
  },
  {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("neogen").setup({ snippet_engine = "luasnip" })
    end,
    keys = {
      "<Leader>nc",
      ":lua require('neogen').generate({ type = 'class' })<CR>",
      { desc = "New Class documentation", noremap = true, silent = true },
    },
  },
  {
    "<Leader>nf",
    ":lua require('neogen').generate({ type = 'func' })<CR>",
    { desc = "New Class documentation", noremap = true, silent = true },
  },
}
