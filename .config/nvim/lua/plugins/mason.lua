return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      "stylua",
      "shellcheck",
      "shfmt",
      "rust-analyzer",
      "pyright",
      "debugpy",
      "ruff",
      "mypy",
      "black",
    },
  },
}
