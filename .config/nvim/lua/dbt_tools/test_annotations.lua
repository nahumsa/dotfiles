local M = {}

local ns = vim.api.nvim_create_namespace("dbt_tools_tests")
local state = {}
local config = {}

local function leading_spaces(line)
  return #(line:match("^%s*") or "")
end

local function trim(value)
  return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function test_name(line)
  local item = trim(line):match("^%-%s*(.+)$")
  if not item or item == "" then
    return nil
  end

  item = item:gsub("%s*#.*$", "")
  item = item:gsub(":%s*$", "")
  item = item:match("^([%w_%.]+)") or item
  return item ~= "" and item or nil
end

local function collect_tests(lines, start_idx, tests_indent)
  local tests = {}

  for i = start_idx + 1, #lines do
    local line = lines[i]
    local indent = leading_spaces(line)
    local stripped = trim(line)

    if stripped ~= "" and not stripped:match("^#") then
      if indent <= tests_indent then
        break
      end

      local name = test_name(line)
      if name then
        table.insert(tests, name)
      end
    end
  end

  return tests
end

local function parse_model_tests_from_yaml(path, model_name)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end

  local result = {
    path = path,
    model_tests = {},
    column_tests = {},
  }

  local model_indent
  local in_model = false
  local current_column
  local current_column_indent

  for i, line in ipairs(lines) do
    local indent = leading_spaces(line)
    local stripped = trim(line)
    local listed_name = stripped:match("^%-%s*name:%s*['\"]?([^'\"#]+)['\"]?")

    if listed_name then
      listed_name = trim(listed_name)
      if listed_name == model_name then
        in_model = true
        model_indent = indent
        current_column = nil
        current_column_indent = nil
      elseif in_model and model_indent and indent <= model_indent then
        break
      elseif in_model then
        current_column = trim(listed_name)
        current_column_indent = indent
      end
    elseif in_model and model_indent and stripped ~= "" and not stripped:match("^#") and indent <= model_indent then
      break
    end

    if in_model then
      local tests_key = stripped:match("^(data_tests):%s*$") or stripped:match("^(tests):%s*$")
      if tests_key then
        local tests = collect_tests(lines, i, indent)
        if current_column and current_column_indent and indent > current_column_indent then
          result.column_tests[current_column] = result.column_tests[current_column] or {}
          vim.list_extend(result.column_tests[current_column], tests)
        else
          vim.list_extend(result.model_tests, tests)
        end
      end
    end
  end

  if #result.model_tests == 0 and vim.tbl_isempty(result.column_tests) then
    return nil
  end

  return result
end

local function find_model_tests(bufnr)
  local dbt = require("dbt_tools")
  local file = vim.api.nvim_buf_get_name(bufnr)
  local root = dbt.project_root(vim.fn.fnamemodify(file, ":h"))
  if not root then
    return nil
  end

  local model_name = vim.fn.fnamemodify(file, ":t:r")
  local yaml_files = vim.fs.find(function(name, path)
    return (name:match("%.ya?ml$") ~= nil)
      and path:match("/models")
      and not path:match("/target")
      and not path:match("/dbt_packages")
  end, { path = root, type = "file", limit = 1000 })

  table.sort(yaml_files, function(a, b)
    local a_same_dir = vim.fn.fnamemodify(a, ":h") == vim.fn.fnamemodify(file, ":h")
    local b_same_dir = vim.fn.fnamemodify(b, ":h") == vim.fn.fnamemodify(file, ":h")
    if a_same_dir ~= b_same_dir then
      return a_same_dir
    end
    return a < b
  end)

  for _, yaml_file in ipairs(yaml_files) do
    local tests = parse_model_tests_from_yaml(yaml_file, model_name)
    if tests then
      tests.model_name = model_name
      return tests
    end
  end
end

local function format_tests(tests)
  local lines = {}

  if #tests.model_tests > 0 then
    table.insert(lines, "model: " .. table.concat(tests.model_tests, ", "))
  end

  local columns = vim.tbl_keys(tests.column_tests)
  table.sort(columns)
  for _, column in ipairs(columns) do
    table.insert(lines, column .. ": " .. table.concat(tests.column_tests[column], ", "))
  end

  return lines
end

local function render_header(bufnr, tests)
  local lines = format_tests(tests)
  if #lines == 0 then
    return
  end

  local virt_lines = {
    { { " dbt tests for " .. tests.model_name .. " ", "Title" } },
  }

  for _, line in ipairs(lines) do
    table.insert(virt_lines, { { "  • " .. line, "Comment" } })
  end

  table.insert(virt_lines, { { "", "Comment" } })

  vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
    virt_lines = virt_lines,
    virt_lines_above = true,
  })
end

local function tested_columns(tests)
  local columns = vim.tbl_keys(tests.column_tests)
  table.sort(columns)
  return columns
end

local function annotate_star_selects(bufnr, lines, columns)
  if #columns == 0 then
    return
  end

  local text = " dbt tested: " .. table.concat(columns, ", ")
  for line_idx, line in ipairs(lines) do
    local trimmed = trim(line)
    local star_from, star_to = line:find("%*")

    if star_to and not trimmed:match("^%-%-") then
      vim.api.nvim_buf_set_extmark(bufnr, ns, line_idx - 1, star_to, {
        virt_text = { { text, "Comment" } },
        virt_text_pos = "inline",
      })
    end
  end
end

local function highlight_tested_columns(bufnr, tests)
  local columns = tested_columns(tests)
  if #columns == 0 then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  annotate_star_selects(bufnr, lines, columns)

  for line_idx, line in ipairs(lines) do
    for _, column in ipairs(columns) do
      local start = 1
      local pattern = "%f[%w_]" .. vim.pesc(column) .. "%f[^%w_]"
      while true do
        local from, to = line:find(pattern, start)
        if not from then
          break
        end

        vim.api.nvim_buf_set_extmark(bufnr, ns, line_idx - 1, from - 1, {
          end_col = to,
          hl_group = "DiagnosticVirtualTextInfo",
        })
        start = to + 1
      end
    end
  end
end

local function show_column_tests(bufnr)
  local tests = state[bufnr]
  if not tests then
    vim.lsp.buf.hover()
    return
  end

  local column = vim.fn.expand("<cword>")
  local column_tests = tests.column_tests[column]
  if not column_tests or #column_tests == 0 then
    vim.notify("No dbt tests found for column '" .. column .. "'", vim.log.levels.INFO)
    return
  end

  local lines = {
    "# dbt tests: `" .. column .. "`",
    "",
  }

  for _, test in ipairs(column_tests) do
    table.insert(lines, "- " .. test)
  end

  table.insert(lines, "")
  table.insert(lines, "_From " .. vim.fn.fnamemodify(tests.path, ":~:.") .. "_")

  vim.lsp.util.open_floating_preview(lines, "markdown", {
    border = "rounded",
    focusable = true,
  })
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  state[bufnr] = nil

  if vim.bo[bufnr].filetype ~= "sql" then
    return
  end

  local file = vim.api.nvim_buf_get_name(bufnr)
  if not file:match("%.sql$") then
    return
  end

  local tests = find_model_tests(bufnr)
  if not tests then
    return
  end

  state[bufnr] = tests
  render_header(bufnr, tests)
  highlight_tested_columns(bufnr, tests)

  vim.keymap.set("n", config.hover_keymap or "K", function()
    show_column_tests(bufnr)
  end, {
    buffer = bufnr,
    desc = "Show dbt column tests",
  })
end

function M.setup(opts)
  config = opts or {}
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("DbtToolsTests", { clear = true }),
    pattern = "*.sql",
    callback = function(event)
      M.refresh(event.buf)
    end,
  })
end

return M
