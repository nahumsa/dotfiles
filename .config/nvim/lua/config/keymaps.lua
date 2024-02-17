local keymap = vim.keymap.set

keymap("n", "<C-d>", "<C-d>zz", { desc = "jump page down centered", remap = true })
keymap("n", "<C-u>", "<C-u>zz", { desc = "jump page up centered", remap = true })
keymap("n", "<C-f>", "<cmd>silent ! zellij-sessionizer ~<CR>", { desc = "create new zellij session", remap = true })
keymap(
  "n",
  "<leader>r",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "replace word", remap = true }
)

-- neogen
keymap(
  "n",
  "<Leader>nc",
  ":lua require('neogen').generate({ type = 'class' })<CR>",
  { desc = "New Class documentation", noremap = true, silent = true }
)

keymap(
  "n",
  "<Leader>nf",
  ":lua require('neogen').generate({ type = 'func' })<CR>",
  { desc = "New Class documentation", noremap = true, silent = true }
)
