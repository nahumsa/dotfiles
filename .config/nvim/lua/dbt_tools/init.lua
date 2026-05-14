local M = {}

M.config = {
  goto_ref_keymap = "<leader>gd",
  tests = {
    enabled = true,
    hover_keymap = "K",
    warn_on_missing_table_tests = true,
  },
}

function M.project_root(start_path)
  start_path = start_path or vim.fn.expand("%:p:h")
  local project_file = vim.fs.find("dbt_project.yml", {
    upward = true,
    path = start_path,
  })[1]

  if not project_file then
    return nil
  end

  return vim.fn.fnamemodify(project_file, ":h")
end

function M.models()
  local root = M.project_root()
  if not root then
    return {}
  end

  local files = vim.fs.find(function(name, path)
    return name:match("%.sql$")
      and path:match("/models")
      and not path:match("/target")
      and not path:match("/dbt_packages")
  end, {
    path = root,
    type = "file",
    limit = 1000,
  })

  table.sort(files)

  return vim.tbl_map(function(path)
    return {
      name = vim.fn.fnamemodify(path, ":t:r"),
      path = path,
    }
  end, files)
end

local function ref_at_or_after_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1]
  local cursor_col = cursor[2] + 1
  local last_line = vim.api.nvim_buf_line_count(0)

  for line_nr = cursor_line, last_line do
    local line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1] or ""
    local search_from = 1

    while true do
      local start_col, end_col = line:find("ref%s*%b()", search_from)
      if not start_col then
        break
      end

      if line_nr > cursor_line or end_col >= cursor_col then
        local ref_call = line:sub(start_col, end_col)
        local quoted_args = {}
        for arg in ref_call:gmatch("['\"]([^'\"]+)['\"]") do
          table.insert(quoted_args, arg)
        end

        if #quoted_args > 0 then
          return quoted_args[#quoted_args]
        end
      end

      search_from = end_col + 1
    end
  end
end

function M.goto_ref()
  local ref_name = ref_at_or_after_cursor()
  if not ref_name then
    vim.notify("No dbt ref() found at or after cursor", vim.log.levels.WARN)
    return
  end

  local project_root = M.project_root(vim.fn.expand("%:p:h"))
  if not project_root then
    vim.notify("No dbt_project.yml found above current file", vim.log.levels.WARN)
    return
  end

  local matches = vim.fs.find(ref_name .. ".sql", { path = project_root, type = "file", limit = 100 })
  matches = vim.tbl_filter(function(path)
    return not path:match("/target/") and not path:match("/dbt_packages/")
  end, matches)

  table.sort(matches, function(a, b)
    local a_is_model = a:match("/models/") ~= nil
    local b_is_model = b:match("/models/") ~= nil
    if a_is_model ~= b_is_model then
      return a_is_model
    end
    return a < b
  end)

  if #matches == 0 then
    vim.notify("No SQL file found for ref('" .. ref_name .. "')", vim.log.levels.WARN)
  elseif #matches == 1 then
    vim.cmd.edit(vim.fn.fnameescape(matches[1]))
  else
    vim.ui.select(matches, {
      prompt = "Select dbt model for ref('" .. ref_name .. "'):",
      format_item = function(path)
        return vim.fn.fnamemodify(path, ":~:.")
      end,
    }, function(choice)
      if choice then
        vim.cmd.edit(vim.fn.fnameescape(choice))
      end
    end)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("DbtToolsKeymaps", { clear = true }),
    pattern = "sql",
    callback = function(event)
      vim.keymap.set("n", M.config.goto_ref_keymap, M.goto_ref, {
        buffer = event.buf,
        desc = "Go to dbt ref() model",
      })
    end,
  })

  if M.config.tests.enabled then
    -- This only reads dbt YAML test declarations for editor annotations.
    -- It does not execute `dbt test`; actual test runs should happen in CI.
    require("dbt_tools.test_annotations").setup(M.config.tests)
  end
end

return M
