return {
  {
    "mireq/luasnip-snippets",
    dependencies = { "L3MON4D3/LuaSnip" },
    init = function()
      -- Mandatory setup function
      require("luasnip_snippets.common.snip_utils").setup()
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    version = "2.*",
    build = "make install_jsregexp",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    init = function()
      local ls = require("luasnip")
      ls.setup({
        -- Required to automatically include base snippets, like "c" snippets for "cpp"
        load_ft_func = require("luasnip_snippets.common.snip_utils").load_ft_func,
        ft_func = require("luasnip_snippets.common.snip_utils").ft_func,
        -- To enable auto expansin
        enable_autosnippets = true,
        -- Uncomment to enable visual snippets triggered using <c-x>
        -- store_selection_keys = '<c-x>',
      })
      -- LuaSnip key bindings
      -- <Tab>/<S-Tab> are handled by nvim-cmp so completion cycling works.
      vim.keymap.set({ "i", "s" }, "<C-E>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true })
    end,
  },
}
