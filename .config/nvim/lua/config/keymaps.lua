local keymap = vim.keymap.set

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
