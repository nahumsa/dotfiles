return {
  {
    dir = vim.fn.stdpath("config"),
    name = "dbt-tools.nvim",
    ft = "sql",
    config = function()
      require("dbt_tools").setup({
        goto_ref_keymap = "<leader>gd",
        tests = {
          enabled = true,
          hover_keymap = "K",
          warn_on_missing_table_tests = true,
        },
      })
    end,
  },
}
