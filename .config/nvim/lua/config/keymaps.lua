local keymap = vim.keymap.set

local function has_words_before()
  local line_nr, col = table.unpack(vim.api.nvim_win_get_cursor(0))
  if col == 0 then
    return false
  end

  local line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, true)[1]
  return line:sub(col, col):match("%s") == nil
end

keymap({ "i", "s" }, "<Tab>", function()
  local has_blink, blink = pcall(require, "blink.cmp")
  if has_blink then
    if blink.is_visible() or blink.is_active() then
      blink.select_next({ auto_insert = false })
      return
    elseif has_words_before() then
      blink.show()
      return
    end
  end

  local has_cmp, cmp = pcall(require, "cmp")
  if has_cmp then
    if cmp.visible() then
      cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
      return
    elseif has_words_before() then
      cmp.complete()
      return
    end
  end

  local has_luasnip, luasnip = pcall(require, "luasnip")
  if has_luasnip and luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
    return
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
end, { desc = "Next completion item", silent = true })

keymap({ "i", "s" }, "<S-Tab>", function()
  local has_blink, blink = pcall(require, "blink.cmp")
  if has_blink and (blink.is_visible() or blink.is_active()) then
    blink.select_prev({ auto_insert = false })
    return
  end

  local has_cmp, cmp = pcall(require, "cmp")
  if has_cmp and cmp.visible() then
    cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
    return
  end

  local has_luasnip, luasnip = pcall(require, "luasnip")
  if has_luasnip and luasnip.jumpable(-1) then
    luasnip.jump(-1)
    return
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
end, { desc = "Previous completion item", silent = true })

keymap("n", "<C-d>", "<C-d>zz", { desc = "jump page down centered", remap = true })
keymap("n", "<C-u>", "<C-u>zz", { desc = "jump page up centered", remap = true })
keymap(
  "n",
  "<leader>r",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "replace word", remap = true }
)
keymap("n", "<Leader>xc", ":call setreg('+', expand('%:t:r') )<CR>",
  { remap = true, desc = "Go to location in clipboard" })

keymap("n", "<Leader>xf", function()
  local file = vim.fn.expand('%')
  local output = {}

  print("SQLFluff: Fixing...")

  vim.fn.jobstart({ "sqlfluff", "fix", file }, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(output, line) end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, "ERROR: " .. line)
          end
        end
      end
    end,
    on_exit = function(_, code)
      vim.cmd("checktime")

      if #output > 0 then
        print(table.concat(output, "\n"))
      else
        if code == 0 then
          print("SQLFluff: Complete (no changes or already clean)")
        else
          print("SQLFluff: Failed (exit code " .. code .. ")")
        end
      end
    end,
  })
end, { desc = "Async SQLFluff fix" })
