local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == "sql" and require("dbt_tools").project_root() ~= nil
end

function source:get_trigger_characters()
  return { "'", '"' }
end

local function ref_completion_context()
  local line_nr, col = table.unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before_cursor = line:sub(1, col)

  if not before_cursor:match("ref%s*%(%s*['\"][%w_]*$") then
    return nil
  end

  local prefix = before_cursor:match("[%w_]*$") or ""
  return {
    line = line_nr - 1,
    start_col = col - #prefix,
    end_col = col,
  }
end

function source:get_completions(_, callback)
  local context = ref_completion_context()
  if not context then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local kind = require("blink.cmp.types").CompletionItemKind.File
  local items = vim.tbl_map(function(model)
    return {
      label = model.name,
      kind = kind,
      detail = "dbt model",
      documentation = {
        kind = "markdown",
        value = "`" .. vim.fn.fnamemodify(model.path, ":~:.") .. "`",
      },
      textEdit = {
        newText = model.name,
        range = {
          start = { line = context.line, character = context.start_col },
          ["end"] = { line = context.line, character = context.end_col },
        },
      },
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
    }
  end, require("dbt_tools").models())

  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

return source
