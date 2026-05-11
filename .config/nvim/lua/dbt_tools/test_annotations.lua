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

local function is_model_file(file, root)
  return file:match("%.sql$")
    and vim.startswith(file, root)
    and file:match("/models/") ~= nil
    and file:match("/target/") == nil
    and file:match("/dbt_packages/") == nil
end

local function find_model_tests(bufnr)
  local dbt = require("dbt_tools")
  local file = vim.api.nvim_buf_get_name(bufnr)
  local root = dbt.project_root(vim.fn.fnamemodify(file, ":h"))
  if not root or not is_model_file(file, root) then
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

  if config.warn_on_missing_table_tests ~= false then
    return {
      model_name = model_name,
      model_tests = {},
      column_tests = {},
      missing_table_tests = true,
    }
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

local function render_missing_table_tests_warning(bufnr, tests)
  local message = "No dbt tests found for table '" .. tests.model_name .. "'"

  vim.diagnostic.set(ns, bufnr, {
    {
      lnum = 0,
      col = 0,
      severity = vim.diagnostic.severity.WARN,
      source = "dbt-tools",
      message = message,
    },
  })

  vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
    virt_lines = {
      { { " ⚠ " .. message .. " ", "DiagnosticWarn" } },
      { { "", "Comment" } },
    },
    virt_lines_above = true,
  })
end

local function render_header(bufnr, tests)
  if tests.missing_table_tests then
    render_missing_table_tests_warning(bufnr, tests)
    return
  end

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

local function strip_sql_comments_and_strings(lines)
  local result = {}
  local in_block_comment = false
  local in_string

  for _, line in ipairs(lines) do
    local chars = {}
    local i = 1

    while i <= #line do
      local two = line:sub(i, i + 1)
      local char = line:sub(i, i)

      if in_block_comment then
        if two == "*/" then
          chars[i] = " "
          chars[i + 1] = " "
          i = i + 2
          in_block_comment = false
        else
          chars[i] = " "
          i = i + 1
        end
      elseif in_string then
        chars[i] = " "
        if char == in_string then
          if line:sub(i + 1, i + 1) == in_string then
            chars[i + 1] = " "
            i = i + 2
          else
            in_string = nil
            i = i + 1
          end
        else
          i = i + 1
        end
      elseif two == "--" then
        for j = i, #line do
          chars[j] = " "
        end
        break
      elseif two == "/*" then
        chars[i] = " "
        chars[i + 1] = " "
        i = i + 2
        in_block_comment = true
      elseif char == "'" or char == '"' or char == "`" then
        chars[i] = " "
        in_string = char
        i = i + 1
      else
        chars[i] = char
        i = i + 1
      end
    end

    table.insert(result, table.concat(chars))
  end

  return result
end

local function previous_significant(code_lines, line_idx, col)
  for row = line_idx, 1, -1 do
    local line = code_lines[row]
    local start_col = row == line_idx and col - 1 or #line
    for i = start_col, 1, -1 do
      local char = line:sub(i, i)
      if not char:match("%s") then
        local word = line:sub(1, i):match("([%w_]+)$")
        return char, word and word:lower() or nil
      end
    end
  end
end

local function next_significant(code_lines, line_idx, col)
  for row = line_idx, #code_lines do
    local line = code_lines[row]
    local start_col = row == line_idx and col + 1 or 1
    for i = start_col, #line do
      local char = line:sub(i, i)
      if not char:match("%s") then
        local word = line:sub(i):match("^([%w_]+)")
        return char, word and word:lower() or nil
      end
    end
  end
end

local function is_in_select_projection(code_lines, line_idx, col)
  local depth = 0
  local select_depths = {}

  for row = 1, line_idx do
    local line = code_lines[row]
    local limit = row == line_idx and col - 1 or #line
    local i = 1

    while i <= limit do
      local char = line:sub(i, i)

      if char == "(" then
        depth = depth + 1
        i = i + 1
      elseif char == ")" then
        depth = math.max(0, depth - 1)
        while #select_depths > 0 and select_depths[#select_depths] > depth do
          table.remove(select_depths)
        end
        i = i + 1
      else
        local word = line:sub(i, limit):match("^([%w_]+)")
        if word then
          word = word:lower()
          if word == "select" then
            table.insert(select_depths, depth)
          elseif word == "from" and select_depths[#select_depths] == depth then
            table.remove(select_depths)
          end
          i = i + #word
        else
          i = i + 1
        end
      end
    end
  end

  return #select_depths > 0
end

local function star_is_select_wildcard(code_lines, line_idx, col)
  if not is_in_select_projection(code_lines, line_idx, col) then
    return false
  end

  local prev_char, prev_word = previous_significant(code_lines, line_idx, col)
  local next_char, next_word = next_significant(code_lines, line_idx, col)

  local valid_prev = prev_char == "."
    or prev_char == ","
    or prev_word == "select"
    or prev_word == "distinct"
    or prev_word == "all"
  local valid_next = next_char == "," or next_word == "from" or next_word == "except" or next_word == "replace"

  return valid_prev and valid_next
end

local function annotate_star_selects(bufnr, lines, columns)
  if #columns == 0 then
    return
  end

  local text = " dbt tested: " .. table.concat(columns, ", ")
  local code_lines = strip_sql_comments_and_strings(lines)

  for line_idx, line in ipairs(code_lines) do
    local start = 1
    while true do
      local star_from, star_to = line:find("%*", start)
      if not star_from then
        break
      end

      if star_is_select_wildcard(code_lines, line_idx, star_from) then
        vim.api.nvim_buf_set_extmark(bufnr, ns, line_idx - 1, star_to, {
          virt_text = { { text, "Comment" } },
          virt_text_pos = "inline",
        })
      end

      start = star_to + 1
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
  vim.diagnostic.reset(ns, bufnr)
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
  if not tests.missing_table_tests then
    highlight_tested_columns(bufnr, tests)
  end

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
