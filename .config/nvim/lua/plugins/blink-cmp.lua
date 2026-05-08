return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      -- Make local modules available to blink's provider loader even when lazy.nvim's
      -- module cache has not indexed newly-created files yet.
      local config_lua = vim.fn.stdpath("config") .. "/lua"
      local lua_paths = config_lua .. "/?.lua;" .. config_lua .. "/?/init.lua;"
      if not package.path:find(config_lua, 1, true) then
        package.path = lua_paths .. package.path
      end

      opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
        preset = "default",
        ["<Tab>"] = { "select_next", "show", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
      })

      opts.sources = opts.sources or {}
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        dbt_refs = {
          name = "dbt refs",
          module = "dbt_tools.blink_source",
          score_offset = 100,
        },
      })

      local sql_sources = opts.sources.per_filetype and opts.sources.per_filetype.sql
      if type(sql_sources) == "table" then
        if not vim.tbl_contains(sql_sources, "dbt_refs") then
          table.insert(sql_sources, 1, "dbt_refs")
        end
        sql_sources.inherit_defaults = true
      else
        opts.sources.per_filetype = opts.sources.per_filetype or {}
        opts.sources.per_filetype.sql = { inherit_defaults = true, "dbt_refs" }
      end
    end,
  },
}
